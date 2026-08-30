# app/rag/config.py

class RAGConfig:
    # Embedding Model
    EMBEDDING_MODEL = "all-MiniLM-L6-v2"
    EMBEDDING_DIMENSION = 384
    
    # Chunking
    CHUNK_SIZE = 500
    CHUNK_OVERLAP = 50
    
    # Vector Database
    CHROMA_DB_PATH = "./chroma_db"
    COLLECTION_NAME = "hostel_policies"
    SIMILARITY_THRESHOLD = 0.6
    
    # Retrieval
    TOP_K_RESULTS = 3
    
    # LLM - Using new Google GenAI SDK
    LLM_MODEL = "gemini-3.6-flash"
    TEMPERATURE = 0.3
    
    # Multi-Language
    SUPPORTED_LANGUAGES = ["en", "hi", "ta", "te"]
    DEFAULT_LANGUAGE = "en"