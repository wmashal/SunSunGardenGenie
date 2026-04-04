# SunSunGardenGenie 🌿

A complete monorepo for the SunSun Garden AR Measurement and AI Design tool.

## 🏗 Project Architecture (Monorepo)
```text
SunSunGardenGenie/
├── app/               # Flutter frontend (UI, AR, HTTP requests)
├── api/               # Python FastAPI middleware (Google GenAI + Supabase DB)
├── supabase/          # Local Docker backend (PostgreSQL + pgvector)
└── README.md          # Project documentation
```

### Data Flow
```
Flutter App
    ↓  GET /products
    ↓  POST /generate-design
FastAPI (api/)
    ↓  queries products table
Supabase (PostgreSQL)
```

Flutter has **no direct database connection** — all data goes through the FastAPI backend.

## ⚙️ Prerequisites
1. **Docker Desktop:** Running in the background.
2. **Flutter SDK:** (v3.41+).
3. **Android Studio:** With an Android Emulator running.
4. **Supabase CLI:** `brew install supabase/tap/supabase` (or use direct binary).
5. **Python 3.10+:** For the AI middleware.
6. **Google AI Studio API Key:** Must have a billing account attached (Free tier quota for image models is 0).

---

## 🚀 Local Setup Guide

### 1. Start the Database (Supabase)
```bash
cd ~/Desktop/SunSunGardenGenie
supabase start
supabase db reset # Applies the SQL schema and inventory
```

### 2. Start the AI Middleware (Python)
```bash
cd ~/Desktop/SunSunGardenGenie/api
python3 -m venv venv
source venv/bin/activate
pip install fastapi uvicorn python-multipart google-genai pillow aiofiles supabase requests python-dotenv

# Start the server
python main.py
```

The API exposes:
- `GET /proxy-image?url=<encoded>` — server-side image proxy; fetches external CDN thumbnails with browser headers and returns them to the Flutter app (bypasses CDN restrictions that block direct mobile requests)
- `GET /products` — returns all products from the database (supports `?search=query`)
- `POST /generate-design` — generates 1 AI landscape design. Accepts `yard_dimensions` (auto-derived from AR measurement) and full product metadata (name, dimensions, color, description) to let the AI reason about fit and colour compatibility before placing products
- `POST /regenerate-with-suggestion` — regenerates the design applying a specific change. Accepts the same `yard_dimensions` field so scale reasoning is preserved across regenerations
- `GET /health` — health check

#### Product Image Handling
Product thumbnail URLs are fetched as-is and passed directly to Gemini. If a fetch fails (HTTP error or network timeout), that product is skipped and excluded from both the image list and the prompt text.

### 3. Start the Frontend (Flutter)
```bash
cd ~/Desktop/SunSunGardenGenie/app
flutter pub get
flutter run
```
*(Select your running Android Emulator)*