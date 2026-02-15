# SunSunGardenGenie 🌿

A complete monorepo for the SunSun Garden AR Measurement and AI Design tool.

## 🏗 Project Architecture (Monorepo)
```text
SunSunGardenGenie/
├── app/               # Flutter frontend (UI, AR, HTTP requests)
├── api/               # Python FastAPI middleware (Google GenAI integration)
├── supabase/          # Local Docker backend (PostgreSQL + pgvector)
└── README.md          # Project documentation
```

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
pip install fastapi uvicorn python-multipart google-genai pillow aiofiles

# Start the server
python main.py
```

### 3. Start the Frontend (Flutter)
```bash
cd ~/Desktop/SunSunGardenGenie/app
flutter pub get
flutter run
```
*(Select your running Android Emulator)*