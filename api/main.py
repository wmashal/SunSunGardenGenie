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
from fastapi.middleware.cors import CORSMiddleware
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

# Enable CORS for mobile app access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

os.makedirs("static", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")


@app.post("/generate-design")
async def generate_design(
        image: UploadFile = File(...),
        prompt: str = Form(default="A beautiful landscape design"),
        selected_products: str = Form(default="[]"),
        is_creative: str = Form(default="false")
):
    print(f"\n{'='*60}")
    print(f"NEW DESIGN REQUEST")
    print(f"{'='*60}")

    # 1. Store Raw Bytes
    image_bytes = await image.read()
    print(f"Received yard image: {len(image_bytes)} bytes")

    # 2. Parse products and fetch their images
    product_bytes_list = []
    product_names = []
    products_list = json.loads(selected_products)

    # Browser-like headers to avoid 406 errors
    headers = {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
        'Referer': 'https://sunsun.co.il/',
    }

    print(f"Selected products: {len(products_list)}")

    for p in products_list:
        product_name = p.get('name', 'Unknown')
        product_names.append(product_name)
        print(f"  - {product_name}")

        thumbnail_url = p.get('thumbnail_url')
        if thumbnail_url:
            try:
                print(f"    Fetching image from: {thumbnail_url}")
                res = requests.get(thumbnail_url, headers=headers, timeout=15)
                if res.status_code == 200:
                    product_bytes_list.append(res.content)
                    print(f"    SUCCESS: {len(res.content)} bytes")
                else:
                    print(f"    FAILED: HTTP {res.status_code}")
            except Exception as e:
                print(f"    FAILED: {e}")

    print(f"Successfully loaded {len(product_bytes_list)}/{len(products_list)} product images")

    # 3. Build product inventory text
    inventory_lines = []
    for i, p in enumerate(products_list):
        line = f"PRODUCT {i+1}: {p.get('name', 'Unknown')}"
        if p.get('color'):
            line += f" | Color: {p.get('color')}"
        if p.get('dimensions'):
            line += f" | Size: {p.get('dimensions')}"
        inventory_lines.append(line)

    inventory_text = "\n".join(inventory_lines)

    # 4. Creative mode rules
    creative_flag = is_creative.lower() == "true"
    print(f"Creative mode: {creative_flag}")

    if creative_flag:
        creativity_rule = """
CREATIVE MODE ENABLED:
- You MAY add small complementary elements like: pathway stones, small solar lights, decorative pebbles
- You must STILL include ALL the selected products listed above
- DO NOT add: pools, pergolas, large furniture, structures, or items not in the product list
"""
    else:
        creativity_rule = """
STRICT MODE - CRITICAL RULES:
- ONLY place the EXACT products listed above in the design
- DO NOT add ANY items that are not in the product list
- DO NOT add: pools, pergolas, fountains, furniture, lights, or decorations unless they are in the product list
- If a product type is not in the list, it should NOT appear in the output image
- The ONLY new elements should be the selected products placed on the existing yard
"""

    # 5. Generator function for each perspective
    async def generate_single_variation(index):
        print(f"\nGenerating Perspective {index + 1}/3...")

        base_yard_image = PIL.Image.open(BytesIO(image_bytes))
        product_images = [PIL.Image.open(BytesIO(b)) for b in product_bytes_list]

        angle_instruction = [
            "Keep the EXACT same camera angle and perspective as the original photo.",
            "Show from a slightly lower, ground-level perspective.",
            "Show from a slightly elevated bird's-eye perspective."
        ][index]

        # Much more explicit prompt
        super_prompt = f"""You are a photorealistic landscape designer. Your task is to modify a backyard photo.

TASK: Place the selected products into this backyard photo.

ORIGINAL PHOTO (Image 1): This is the backyard to modify. KEEP the same:
- Fences, walls, and boundaries
- House structure
- Overall lighting and atmosphere
- Camera angle: {angle_instruction}

SELECTED PRODUCTS TO ADD (Images 2+):
{inventory_text}

The product reference images show EXACTLY what items to place. Place ONLY these items.

USER'S VISION: {prompt}

{creativity_rule}

OUTPUT REQUIREMENTS:
1. Generate a photorealistic image of the backyard WITH the selected products placed naturally
2. The backyard structure (fences, house, etc.) must remain the same
3. Products should be placed on the grass/ground area appropriately scaled
4. Maintain realistic lighting and shadows

QUANTITY ESTIMATE:
After generating, list how many of each product you placed:
{chr(10).join([f'- {name}: [quantity]' for name in product_names])}
"""

        # Build content list: prompt first, then yard image, then product images
        content_list = [super_prompt, base_yard_image] + product_images

        print(f"  Sending to Gemini: 1 prompt + 1 yard image + {len(product_images)} product images")

        response = await asyncio.to_thread(
            client.models.generate_content,
            model="gemini-2.5-flash-image",
            contents=content_list
        )

        timestamp = int(time.time() * 1000)
        output_filename = f"design_var_{index}_{timestamp}.jpg"
        output_path = f"static/{output_filename}"
        summary_text = ""

        if response.candidates:
            for part in response.candidates[0].content.parts:
                if part.text:
                    summary_text += part.text + "\n"
                if part.inline_data:
                    img = PIL.Image.open(BytesIO(part.inline_data.data))
                    img.save(output_path)
                    print(f"  Saved: {output_path}")

        url = f"http://10.0.2.2:8000/{output_path}"
        return url, summary_text.strip()

    try:
        # Run all 3 perspectives in parallel
        tasks = [generate_single_variation(i) for i in range(3)]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        successful_results = []
        for i, res in enumerate(results):
            if isinstance(res, Exception):
                print(f"Perspective {i + 1} FAILED: {res}")
            else:
                successful_results.append(res)

        if not successful_results:
            return {"status": "error", "message": "All design generations failed"}

        image_urls = [res[0] for res in successful_results]
        all_summaries = [res[1] for res in successful_results if res[1]]
        final_summary = all_summaries[0] if all_summaries else "Design completed successfully."

        print(f"\n{'='*60}")
        print(f"COMPLETED: {len(successful_results)}/3 perspectives generated")
        print(f"{'='*60}\n")

        return {
            "status": "success",
            "result_image_urls": image_urls,
            "summary": final_summary
        }
    except Exception as e:
        print(f"API Error: {repr(e)}")
        return {"status": "error", "message": str(e)}


@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "SunSun Garden Genie AI"}


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
