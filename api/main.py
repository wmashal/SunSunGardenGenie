import asyncio
import time
import os
import json
from io import BytesIO
import PIL.Image
from PIL import ImageFile
import requests
from fastapi import FastAPI, File, UploadFile, Form
from fastapi.staticfiles import StaticFiles
import uvicorn
from dotenv import load_dotenv
from google import genai

# Prevent image truncation crashes
ImageFile.LOAD_TRUNCATED_IMAGES = True

load_dotenv()
api_key = os.getenv("GOOGLE_API_KEY")
if not api_key:
    raise ValueError("GOOGLE_API_KEY not found in .env file")

client = genai.Client(api_key=api_key)
app = FastAPI(title="SunSun Garden Genie AI")

os.makedirs("static", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")

@app.post("/generate-design")
async def generate_design(
        image: UploadFile = File(...),
        prompt: str = Form(default="A beautiful landscape design"),
        selected_products: str = Form(default="[]"),
        is_creative: str = Form(default="false")
):
    print(f"--- NEW ARCHITECTURAL REQUEST (3 PERSPECTIVES) ---")

    # 1. Store Raw Bytes (Solves the "Silent Crash" Stream Exhaustion)
    image_bytes = await image.read()

    product_bytes_list = []
    context_items = []
    products_list = json.loads(selected_products)

    for p in products_list:
        context_items.append(f"- {p['name']} (Color: {p['color']}, Size: {p['dimensions']})")
        if p.get('thumbnail_url'):
            try:
                res = requests.get(p['thumbnail_url'])
                if res.status_code == 200:
                    product_bytes_list.append(res.content)
            except Exception as e:
                print(f"Failed to load image for {p['name']}: {e}")

    inventory_context = "\n".join(context_items)

    # 2. Creative Override Logic
    creative_flag = is_creative.lower() == "true"
    if creative_flag:
        creativity_rule = "CREATIVE MODE: You may add minor complementary landscape elements (small lighting, pathway stones, plants). DO NOT add large structures like tents or pools."
    else:
        creativity_rule = "ZERO HALLUCINATION RULE: STRICTLY FORBIDDEN from generating tents, pergolas, pools, or imaginary furniture. ONLY use the exact products provided."

    # 3. The Generator Function
    async def generate_single_variation(index):
        print(f"Generating Perspective {index + 1}...")

        # Create fresh images for THIS specific run
        base_yard_image = PIL.Image.open(BytesIO(image_bytes))
        product_images = [PIL.Image.open(BytesIO(b)) for b in product_bytes_list]

        # NEW: Driving 3 distinct camera angles
        angle_instruction = [
            "Maintain the exact original camera perspective and angle.",
            "Render from a lower, wider ground-level perspective to showcase the depth of the yard.",
            "Render from a slightly elevated, diagonal perspective to show the overall layout of the space."
        ][index]

        # NEW: A universal, generic prompt that analyzes ANY photo
        super_prompt = (
            f"You are a master 3D landscape architectural visualizer. \n"
            f"1. ENVIRONMENT ANALYSIS: The FIRST image is the ANCHOR PHOTO. Analyze this space to understand the architectural style, lighting, and permanent boundary structures (walls, fences, buildings).\n"
            f"2. PERSPECTIVE SHIFT: {angle_instruction} You must preserve the general architectural style and vibe of the original space, even if the angle changes.\n"
            f"3. REDESIGN: Identify the primary ground space (e.g., existing grass, dirt, or paving). Replace this entire ground area with a new layout matching this vision: '{prompt}'.\n"
            f"4. MANDATORY INVENTORY: You MUST include EVERY product provided in the reference images. Scale them correctly to the new perspective.\n"
            f"5. {creativity_rule}\n"
            f"6. QUANTITIES: Suggest exact quantities for these items based on the visual scale: \n{inventory_context}\n"
        )

        response = await asyncio.to_thread(
            client.models.generate_content,
            model="gemini-2.5-flash-image",
            contents=[super_prompt, base_yard_image] + product_images
        )

        output_filename = f"design_var_{index}_{int(time.time())}.jpg"
        output_path = f"static/{output_filename}"
        summary_text = ""

        if response.candidates:
            for part in response.candidates[0].content.parts:
                if part.text:
                    summary_text += part.text + "\n"
                if part.inline_data:
                    img = PIL.Image.open(BytesIO(part.inline_data.data))
                    img.save(output_path)

        url = f"http://10.0.2.2:8000/{output_path}"
        return url, summary_text.strip()

    try:
        # 4. Run Sequentially
        results = []
        for i in range(3):
            res = await generate_single_variation(i)
            results.append(res)

        image_urls = [res[0] for res in results]
        final_summary = results[0][1] if results[0][1] else "Design completed. Swipe left/right to view different perspectives."

        print("--- ALL 3 PERSPECTIVES COMPLETED SUCCESSFULLY ---")
        return {
            "status": "success",
            "result_image_urls": image_urls,
            "summary": final_summary
        }
    except Exception as e:
        error_msg = repr(e)
        print(f"API Error: {error_msg}")
        return {"status": "error", "message": str(e)}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)