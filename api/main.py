import asyncio
import time
import os
import json
import base64
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
from supabase import create_client, Client

ImageFile.LOAD_TRUNCATED_IMAGES = True

load_dotenv()
api_key = os.getenv("GOOGLE_API_KEY")
if not api_key:
    raise ValueError("GOOGLE_API_KEY not found in .env file")

supabase_url = os.getenv("SUPABASE_URL")
supabase_service_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
if not supabase_url or not supabase_service_key:
    raise ValueError("SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not found in .env file")

client = genai.Client(api_key=api_key)
supabase: Client = create_client(supabase_url, supabase_service_key)
app = FastAPI(title="SunSun Garden Genie AI")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

os.makedirs("static", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")


@app.get("/proxy-image")
async def proxy_image(url: str):
    """Fetch an external image server-side and return it to the Flutter app.
    Bypasses CDN restrictions that block direct mobile HTTP requests."""
    from fastapi.responses import Response
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'image/webp,image/png,image/jpeg,image/*,*/*;q=0.8',
            'Referer': 'https://sunsun.co.il/',
        }
        res = requests.get(url, headers=headers, timeout=10)
        if res.status_code == 200:
            content_type = res.headers.get('content-type', 'image/jpeg')
            return Response(content=res.content, media_type=content_type)
        return Response(status_code=res.status_code)
    except Exception:
        return Response(status_code=502)


@app.get("/products")
async def get_products(search: str = None):
    query = supabase.from_("products").select(
        "id, name, category, description, dimensions, color, thumbnail_url, ai_tags"
    )
    if search:
        query = query.or_(f"name.ilike.%{search}%,description.ilike.%{search}%")
    response = query.execute()
    return response.data


def _fetch_product_images(products_list: list) -> tuple[list, list]:
    """Fetch and validate images for all selected products.
    Returns (product_data_list, product_bytes_list) in sync — only successful fetches included."""
    product_data_list = []
    product_bytes_list = []

    headers = {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'image/webp,image/png,image/jpeg,image/*,*/*;q=0.8',
        'Referer': 'https://sunsun.co.il/',
    }

    for p in products_list:
        name = p.get('name', 'Unknown')
        url = p.get('thumbnail_url', '')
        print(f"  - {name}")
        if url:
            try:
                # Handle data: URIs (base64-encoded inline images)
                if url.startswith('data:'):
                    header, encoded = url.split(',', 1)
                    img_bytes = base64.b64decode(encoded)
                    PIL.Image.open(BytesIO(img_bytes)).verify()
                    product_data_list.append(p)
                    product_bytes_list.append(img_bytes)
                    print(f"    OK (data URI): {len(img_bytes)} bytes")
                else:
                    print(f"    Fetching: {url}")
                    res = requests.get(url, headers=headers, timeout=15)
                    if res.status_code == 200:
                        PIL.Image.open(BytesIO(res.content)).verify()
                        product_data_list.append(p)
                        product_bytes_list.append(res.content)
                        print(f"    OK: {len(res.content)} bytes")
                    else:
                        print(f"    FAILED: HTTP {res.status_code}")
            except Exception as e:
                print(f"    FAILED: {e}")
        else:
            print(f"    No thumbnail URL — including in prompt without image")
            # Still include in product data even without an image so it appears in the design brief
            product_data_list.append(p)
            product_bytes_list.append(None)

    return product_data_list, product_bytes_list


@app.post("/generate-design")
async def generate_design(
        image: UploadFile = File(...),
        prompt: str = Form(default="A beautiful landscape design"),
        selected_products: str = Form(default="[]"),
        is_creative: str = Form(default="false"),
        yard_dimensions: str = Form(default=""),
):
    print(f"\n{'='*60}")
    print(f"NEW DESIGN REQUEST")
    print(f"{'='*60}")

    image_bytes = await image.read()
    print(f"Received yard image: {len(image_bytes)} bytes")

    products_list = json.loads(selected_products)
    print(f"Selected products: {len(products_list)}")

    product_data_list, product_bytes_list = _fetch_product_images(products_list)

    print(f"Loaded {sum(1 for b in product_bytes_list if b is not None)}/{len(products_list)} product images")
    print(f"Yard dimensions: {yard_dimensions or 'not provided'}")
    print(f"\nGenerating design...")

    try:
        result_url, summary = await _run_generation(
            image_bytes=image_bytes,
            product_data_list=product_data_list,
            product_bytes_list=product_bytes_list,
            prompt=prompt,
            yard_dimensions=yard_dimensions,
            suggestion=None,
            index=0,
        )

        print(f"\n{'='*60}")
        print(f"COMPLETED")
        print(f"{'='*60}\n")

        return {
            "status": "success",
            "result_image_urls": [result_url],
            "summary": summary,
        }
    except Exception as e:
        print(f"API Error: {repr(e)}")
        return {"status": "error", "message": str(e)}


async def _run_generation(
    image_bytes: bytes,
    product_data_list: list,
    product_bytes_list: list,
    prompt: str,
    yard_dimensions: str,
    suggestion: str | None,
    index: int,
) -> tuple[str, str]:

    base_yard_image = PIL.Image.open(BytesIO(image_bytes))

    # Only pass images that were successfully fetched
    images_with_index = [(i, b) for i, b in enumerate(product_bytes_list) if b is not None]
    product_pil_images = [PIL.Image.open(BytesIO(b)) for _, b in images_with_index]

    # Build per-product detail block for the prompt
    product_catalog_lines = []
    image_counter = 2  # Image 1 is always the yard
    for i, p in enumerate(product_data_list):
        name = p.get('name', 'Unknown')
        category = p.get('category', '')
        description = p.get('description', '')
        dimensions = p.get('dimensions', '')
        color = p.get('color', '')

        detail_parts = []
        if category:
            detail_parts.append(f"category={category}")
        if dimensions:
            detail_parts.append(f"size={dimensions}")
        if color:
            detail_parts.append(f"color={color}")
        if description:
            detail_parts.append(f"desc={description}")

        has_image = product_bytes_list[i] is not None
        if has_image:
            image_ref = f"→ Image {image_counter}"
            image_counter += 1
        else:
            image_ref = "→ no image, use description only"

        detail_str = " | ".join(detail_parts)
        product_catalog_lines.append(f"  [{i+1}] {name}  ({detail_str})  {image_ref}")

    product_catalog = "\n".join(product_catalog_lines)

    # Yard dimensions section
    yard_context = ""
    if yard_dimensions and yard_dimensions.strip():
        yard_context = f"""
━━━ YARD DIMENSIONS ━━━
The yard is approximately {yard_dimensions.strip()}.
Use this to judge realistic scale only. ALL selected products must appear — no exceptions.
Note any sizing or colour observations in NOTES only.
"""

    # Suggestion section
    suggestion_section = ""
    if suggestion and suggestion.strip():
        suggestion_section = f"""
━━━ CHANGE REQUEST ━━━
The customer reviewed the previous design and requests this specific change:
"{suggestion.strip()}"
Apply ONLY this change. Keep all other products and placements identical.
"""

    super_prompt = f"""You are a photorealistic image editor. Your task is to EDIT the provided yard photograph by placing furniture and plants into it.

━━━ YOUR INPUT IMAGES ━━━
  • Image 1 = the customer's REAL yard photo. This is your canvas. Output must show THIS EXACT yard.
{product_catalog}

━━━ CRITICAL INSTRUCTION ━━━
You MUST output an edited version of Image 1. Do NOT generate a new scene. Do NOT invent a different yard.
Copy Image 1 pixel-for-pixel as your base, then composite the products into it.
The fence, ground, sky, buildings, lighting — everything in Image 1 stays exactly as-is.

━━━ DESIGN STYLE ━━━
{prompt}
{yard_context}{suggestion_section}
━━━ PLACEMENT RULES ━━━

RULE A — YARD IS YOUR CANVAS
  Start from Image 1. Output must be a recognisable photo of the same yard.
  Same fence, same ground, same sky, same buildings, same lighting direction.

RULE B — ALL PRODUCTS MUST APPEAR
  Every product listed above must be visible in the output.
  For products without a reference image: render them from description and dimensions.

RULE C — RENDER PRODUCTS FAITHFULLY
  Each product must look exactly like its reference image — same colour, same shape.
  Only adjust perspective/foreshortening to match its placement position in the yard.

RULE D — NO INVENTED OBJECTS
  Do not add anything not in the product list. No extra furniture, pots, lights, or plants.

RULE E — PHYSICAL REALISM
  • Furniture bases and legs rest on the ground plane.
  • Plants are in soil — no nursery pots or plastic bags visible.
  • All products cast shadows matching Image 1's light direction.
  • Scale is accurate: a 2 m tree should appear 2 m tall relative to the fence.

━━━ OUTPUT FORMAT ━━━
Output the edited yard image only.
"""

    # Content list: prompt → yard image → product images (only those with valid bytes)
    content_list = [super_prompt, base_yard_image] + product_pil_images
    print(f"  Prompt + yard + {len(product_pil_images)} product images → Gemini")

    from google.genai import types as genai_types
    response = await asyncio.to_thread(
        client.models.generate_content,
        model="gemini-3.1-flash-image-preview",
        contents=content_list,
        config=genai_types.GenerateContentConfig(
            response_modalities=["IMAGE", "TEXT"],
        ),
    )

    timestamp = int(time.time() * 1000)
    output_path = f"static/design_{index}_{timestamp}.jpg"

    if response.candidates:
        for part in response.candidates[0].content.parts:
            if part.inline_data:
                img = PIL.Image.open(BytesIO(part.inline_data.data))
                img.save(output_path)
                print(f"  Saved: {output_path}")

    return f"http://10.0.2.2:8000/{output_path}", ""


@app.post("/regenerate-with-suggestion")
async def regenerate_with_suggestion(
        image: UploadFile = File(...),
        prompt: str = Form(default="A beautiful landscape design"),
        selected_products: str = Form(default="[]"),
        suggestion: str = Form(default=""),
        yard_dimensions: str = Form(default=""),
):
    print(f"\n{'='*60}")
    print(f"REGENERATE WITH SUGGESTION: {suggestion}")
    print(f"{'='*60}")

    image_bytes = await image.read()
    products_list = json.loads(selected_products)

    product_data_list, product_bytes_list = _fetch_product_images(products_list)

    try:
        result_url, summary = await _run_generation(
            image_bytes=image_bytes,
            product_data_list=product_data_list,
            product_bytes_list=product_bytes_list,
            prompt=prompt,
            yard_dimensions=yard_dimensions,
            suggestion=suggestion,
            index=0,
        )
        return {
            "status": "success",
            "result_image_urls": [result_url],
            "summary": summary,
        }
    except Exception as e:
        print(f"Regenerate Error: {repr(e)}")
        return {"status": "error", "message": str(e)}


@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "SunSun Garden Genie AI"}


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
