🏠 HostelSwap – Hostel Room Swap Matchmaker

![Flutter](https://img.shields.io/badge/Flutter-3.24-blue?logo=flutter)
![FastAPI](https://img.shields.io/badge/FastAPI-0.115-green?logo=fastapi)
![Supabase](https://img.shields.io/badge/Supabase-2.0-3ECF8E?logo=supabase)
![OpenAI](https://img.shields.io/badge/OpenAI-GPT--4o--mini-412991?logo=openai)
![License](https://img.shields.io/badge/License-MIT-yellow)

## 📌 Overview

HostelSwap is a Flutter‑based mobile and web application that solves the chaotic hostel room‑shifting problem faced by students. Instead of spamming WhatsApp groups with "Anyone want BH‑1?", students can use a dedicated matchmaking platform to post, browse, and find compatible swap partners — all while keeping their contact information private until they choose to reveal it.

🎯 **Goal:** Make hostel shifting simple, transparent, and stress‑free.

## ✨ Features

| Feature | Description |
|---|---|
| 🤖 AI‑Powered Request Intake | Type naturally — the LLM extracts hostel, AC type, and seater capacity. |
| 🔍 Smart Dashboard & Filters | Browse requests filtered by hostel, AC, seater, and gender. |
| ❤️ Express Interest | Click once to show interest; duplicate applications are prevented. |
| 📱 Applicant Management | Requester sees a list of applicants with real‑time push notifications (FCM). |
| 🔒 Privacy‑Preserving Contact Reveal | Phone numbers are hidden until the requester explicitly reveals them. |
| ✅ Finalise & Auto‑Cleanup | Select the best applicant; others are auto‑notified when the request is fulfilled. |
| ⏳ Request Lifecycle | Withdraw anytime; inactive requests auto‑delete after 5 days. |
| 📚 RAG‑Powered Policy Assistant | Ask about hostel rules — the bot answers using your official documents (Retrieval‑Augmented Generation). |
| 🌐 Multi‑Language | Supports English, Hindi, Tamil, and Telugu (translation via OpenAI). |
| 📱 Cross‑Platform | Works on Web, Android, and iOS with a single Flutter codebase. |

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         FLUTTER APP                             │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────┐    ┌──────────────────────────────┐  │
│  │   Supabase Direct    │    │   FastAPI (via ngrok/cloud)  │  │
│  │   (Realtime DB)      │    │   (Chatbot + RAG + FCM)      │  │
│  └──────────────────────┘    └──────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    FASTAPI BACKEND                              │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────┐  │
│  │  Supabase    │  │  ChromaDB    │  │  OpenAI API         │  │
│  │  (CRUD)      │  │  (Vectors)   │  │  (LLM + RAG)        │  │
│  └──────────────┘  └──────────────┘  └─────────────────────┘  │
│  ┌──────────────┐  ┌──────────────┐                           │
│  │  FCM Backend │  │  Scheduler   │                           │
│  │ (Notif.)     │  │ (Auto‑Delete)│                           │
│  └──────────────┘  └──────────────┘                           │
└─────────────────────────────────────────────────────────────────┘
```

## 🧰 Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| Frontend | Flutter + Riverpod | Cross‑platform UI with reactive state |
| Backend | FastAPI (Python) | Async API, AI parsing, RAG orchestration |
| Database | Supabase (PostgreSQL) | Cloud database + real‑time subscriptions |
| Vector DB | ChromaDB | Local storage of document embeddings |
| Embeddings | all‑MiniLM‑L6‑v2 (Sentence‑Transformers) | Free, CPU‑friendly, no API cost |
| LLM | OpenAI GPT‑4o‑mini | Intent classification, structured extraction, RAG generation |
| Push Notifications | Firebase Cloud Messaging | Real‑time alerts |
| Tunneling | ngrok / Cloudflare Tunnel | Expose local dev server |

## 🚀 Getting Started

### Prerequisites

- Python 3.10+
- Flutter SDK (with Chrome/Edge for web)
- Supabase account (free tier)
- OpenAI API Key (from [platform.openai.com](https://platform.openai.com))
- Firebase project (for push notifications – optional for development)

### Backend Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/hostelswap.git
cd hostelswap/backend

# Create virtual environment
python -m venv venv
source venv/bin/activate   # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Copy environment variables
cp .env.example .env
# Edit .env with your Supabase URL, anon key, OpenAI API key, etc.

# Run the FastAPI server
uvicorn app.main:app --reload
```

> **Note:** The server will use sample RAG data if you don't provide a hostel policy PDF. Place your own PDF at `docs/hostel_policy.pdf` to enable real policy queries.

### Frontend Setup

```bash
cd ../frontend

# Install Flutter dependencies
flutter pub get

# Update API configuration
# Edit lib/config/api_config.dart – set baseUrl to your backend URL
# Edit lib/config/app_constants.dart – add Supabase credentials

# Run the app
flutter run -d chrome          # Web
# flutter run -d android        # Android
# flutter run -d ios            # iOS (macOS only)
```

## 📲 Usage Walkthrough

1. **Login** – Enter your College ID and select your Gender.
2. **Post a Request** – Use the chatbot (or the manual form) to describe your swap desire:
   > "I have BH‑2 Non‑AC 3‑seater, want BH‑1 AC 2‑seater."
3. **Browse** – Filter requests by hostel, AC, and seater type.
4. **Express Interest** – Click "Express Interest" on any compatible request.
5. **Manage Applicants** – If you're the requester, you'll see a list of applicants.
6. **Reveal Contact** – Choose a student and reveal their phone number (they'll also see yours).
7. **Finalise** – Move to WhatsApp to finalise the swap, then click "Finalise Swap" in the app to close the request.

## 🧪 Testing

### Test the Backend (with curl)

```bash
# Health check
curl http://localhost:8000/health

# RAG query
curl -X POST http://localhost:8000/rag/query \
  -H "Content-Type: application/json" \
  -d '{"query": "What is the deadline for hostel shift?"}'

# Chatbot (swap request)
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"user_id":"2024CS101", "message":"I have BH-2 Non-AC 3-seater, want BH-1 AC 2-seater"}'
```

### Test the Frontend

Use the built‑in Test Connection screen (click the network icon in the AppBar) to verify backend connectivity.

The Dashboard and My Requests screens allow full CRUD operations.

## 📁 Project Structure

```
hostelswap/
├── backend/
│   ├── app/
│   │   ├── main.py               # FastAPI entry point
│   │   ├── database.py           # Supabase client
│   │   ├── models/               # Pydantic models
│   │   ├── services/             # Supabase & FCM services
│   │   ├── rag/                  # RAG pipeline (loader, embeddings, vector store, LLM handler)
│   │   └── utils/                # Validators
│   ├── docs/                     # Hostel policy PDFs
│   ├── chroma_db/                # Vector DB storage (auto‑generated)
│   ├── .env                      # Environment variables
│   └── requirements.txt
└── frontend/
    ├── lib/
    │   ├── main.dart
    │   ├── config/               # API & app constants
    │   ├── models/               # Data models (User, Request, Interest)
    │   ├── providers/            # Riverpod state providers
    │   ├── screens/              # Login, Dashboard, My Requests, Chatbot, etc.
    │   ├── services/             # Supabase, FCM, ApiService, StorageService
    │   ├── widgets/              # Reusable UI components
    │   └── utils/                # Helpers (responsive, validators)
    ├── assets/
    ├── pubspec.yaml
    └── ...
```

## 🤝 Contributing

Contributions are welcome! Please open an issue or submit a pull request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

## 📧 Contact

 – shreeyansh and harshit singh


## 🙏 Acknowledgements

- **OpenAI** – for the LLM API
- **Supabase** – for the real‑time backend
- **Flutter** – for the amazing cross‑platform framework
- **Sentence‑Transformers** – for the embedding model
