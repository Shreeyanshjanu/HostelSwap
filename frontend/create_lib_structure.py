from pathlib import Path

# Flutter lib directory
BASE_DIR = Path("lib")

# Folder structure
folders = [
    "config",
    "models",
    "services",
    "providers",
    "screens",
    "widgets",
    "utils",
]

# Dart files
files = {
    "main.dart": "",

    # config
    "config/api_config.dart": "// API URLs (ngrok + Supabase)\n",
    "config/app_constants.dart": "// Hostel lists, room types, etc.\n",

    # models
    "models/user_model.dart": "",
    "models/request_model.dart": "",
    "models/interest_model.dart": "",
    "models/chat_unlock_model.dart": "",

    # services
    "services/supabase_service.dart": "// Supabase CRUD + Realtime\n",
    "services/api_service.dart": "// FastAPI endpoints (chatbot, RAG)\n",
    "services/fcm_service.dart": "// Firebase push notifications\n",
    "services/auth_service.dart": "// Password-less login\n",

    # providers
    "providers/auth_provider.dart": "// Riverpod - User state\n",
    "providers/request_provider.dart": "// Riverpod - Requests state\n",
    "providers/interest_provider.dart": "// Riverpod - Interests state\n",

    # screens
    "screens/login_screen.dart": "",
    "screens/dashboard_screen.dart": "",
    "screens/create_request_screen.dart": "",
    "screens/my_requests_screen.dart": "",
    "screens/applicants_list_screen.dart": "",
    "screens/chatbot_screen.dart": "",

    # widgets
    "widgets/request_card.dart": "// Dashboard card widget\n",
    "widgets/filter_bar.dart": "// Hostel/AC/Seater filters\n",
    "widgets/applied_badge.dart": '// "Applied" indicator\n',
    "widgets/chat_bubble.dart": "// Chat UI bubbles\n",
    "widgets/loading_shimmer.dart": "// Skeleton loading\n",

    # utils
    "utils/validators.dart": "// College ID validation\n",
    "utils/responsive_helper.dart": "// Web/Mobile responsive utilities\n",
}

# Create folders
for folder in folders:
    (BASE_DIR / folder).mkdir(parents=True, exist_ok=True)

# Create files
for file_path, content in files.items():
    path = BASE_DIR / file_path

    if not path.exists():
        path.write_text(content, encoding="utf-8")
        print(f"Created: {path}")
    else:
        print(f"Already exists: {path}")

print("\n"" Flutter lib structure created successfully!")