from pathlib import Path

ROOT = Path(".")

FILES = [
    "app/__init__.py",
    "app/main.py",
    "app/rag/__init__.py",
    "app/rag/pipeline.py",
    "app/rag/document_loader.py",
    "app/rag/embedding.py",
    "app/rag/vector_store.py",
    "app/rag/llm_handler.py",
    "app/rag/config.py",
    "app/services/supabase_service.py",
    "app/services/fcm_service.py",
    "app/models/user_model.py",
    "app/models/request_model.py",
    "app/models/interest_model.py",
    "docs/hostel_policy.pdf",
    "chroma_db/.gitkeep",
    "requirements.txt",
    ".env",
    "firebase-credentials.json",
]

CONTENTS = {
    "app/main.py": """from fastapi import FastAPI

app = FastAPI(title="HostelSwap Backend")


@app.get("/")
def health_check():
    return {"status": "ok", "service": "HostelSwap Backend"}
""",
    "requirements.txt": """fastapi
uvicorn[standard]
python-dotenv
supabase
firebase-admin
google-generativeai
chromadb
pypdf
""",
    ".env": """# Backend environment variables
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
GEMINI_API_KEY=
""",
    "firebase-credentials.json": """{
  "type": "service_account"
}
""",
}

for rel_path in FILES:
    path = ROOT / rel_path
    path.parent.mkdir(parents=True, exist_ok=True)

    # Do not overwrite an existing hostel policy PDF.
    if path.suffix.lower() == ".pdf":
        if not path.exists():
            path.write_bytes(b"")
        continue

    if path.name == ".gitkeep":
        content = ""
    else:
        content = CONTENTS.get(rel_path, "")

    if not path.exists():
        path.write_text(content, encoding="utf-8")

print(f"Backend template created at: {ROOT.resolve()}")