from fastapi import FastAPI, File, UploadFile, Form
from fastapi.staticfiles import StaticFiles
import uvicorn
import json
import os
from dotenv import load_dotenv
import PIL.Image
from io import BytesIO
import requests

# Import the NEW unified SDK
from google import genai

# Load variables from .env
load_dotenv()

# Fetch the key from the environment
api_key = os.getenv("GOOGLE_API_KEY")
# Initialize the new Client
if not api_key:
    raise ValueError("GOOGLE_API_KEY not found in .env file")

# Initialize the Client with the secure key
client = genai.Client(api_key=api_key)

app = FastAPI(title="SunSun Garden Genie AI Middleware")

# Create a local folder to host the generated images for Flutter
os.makedirs("static", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")

@app.post("/generate-design")
async def generate_design(
        image: UploadFile = File(...),
        prompt: str = Form(...),
        selected_products: str = Form(...)
):
    print("--- NEW MULTI-IMAGE DESIGN REQUEST RECEIVED ---")

    # 1. Read the base yard image uploaded from Flutter
    try:
        image_bytes = await image.read()
        base_yard_image = PIL.Image.open(BytesIO(image_bytes))
    except Exception as e:
        print(f"Image processing error: {e}")
        return {"status": "error", "message": f"Could not read yard image: {str(e)}"}

    # 2. Parse the selected products AND download their images
    product_images = []
    context_items = []
    try:
        products_list = json.loads(selected_products)
        for i, p in enumerate(products_list):
            # We index the products so the AI knows which image is which
            item_num = i + 1
            detail = f"Product Image {item_num} - {p['name']} (Color: {p['color']}): {p['description']}"
            context_items.append(detail)

            # Download the actual thumbnail to send to the AI
            if p.get('thumbnail_url'):
                try:
                    res = requests.get(p['thumbnail_url'])
                    if res.status_code == 200:
                        p_img = PIL.Image.open(BytesIO(res.content))
                        product_images.append(p_img)
                except Exception as img_err:
                    print(f"Failed to fetch product image {p['name']}: {img_err}")

        inventory_context = "\n".join(context_items)
    except Exception as e:
        print(f"Error parsing products: {e}")
        inventory_context = "No specific plants selected."

    # 3. Build the Multi-Image Super Prompt
    super_prompt = (
        f"You are a master landscape architect. Redesign the provided backyard photo exactly as requested. "
        f"User Vision: '{prompt}'. "
        f"CRITICAL INSTRUCTIONS: "
        f"1. The FIRST image provided is the base yard. You must completely remove the red deck and build a new patio. "
        f"2. The SUBSEQUENT images provided are the exact products you MUST feature in the design: \n{inventory_context}\n"
        f"3. Do not invent generic furniture. Look directly at the provided product images and extract their exact shape, texture, and color to place them in the scene. "
        f"Maintain the exact structural perspective of the house, the satellite dish, and the wooden fence."
    )
    print(f"Super Prompt: \n{super_prompt}")

    try:
        # 4. Assemble the payload: [Text Prompt, Base Yard Photo, Product 1, Product 2...]
        api_contents = [super_prompt, base_yard_image] + product_images

        print(f"Calling AI with {len(api_contents) - 1} total images... (Takes 5-15 seconds)")
        response = client.models.generate_content(
            model="gemini-2.5-flash-image",
            contents=api_contents,
        )

        output_filename = "latest_design.jpg"
        output_path = f"static/{output_filename}"

        # 5. Extract and save the result
        for part in response.candidates[0].content.parts:
            if part.inline_data:
                img_out = PIL.Image.open(BytesIO(part.inline_data.data))
                img_out.save(output_path)
                print(f"Image saved successfully to {output_path}")
                break

        # 6. Return the URL to Flutter
        return {
            "status": "success",
            "message": "Design generated successfully.",
            "result_image_url": f"http://10.0.2.2:8000/static/{output_filename}?v=2"
        }

    except Exception as e:
        print(f"AI Generation Error: {e}")
        return {
            "status": "error",
            "message": str(e)
        }

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)