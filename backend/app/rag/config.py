class RAGConfig:
    EMBEDDING_MODEL = "all-MiniLM-L6-v2"
    EMBEDDING_DIMENSION = 384
    
    CHUNK_SIZE = 500
    CHUNK_OVERLAP = 50
    
    CHROMA_DB_PATH = "rag/chroma_db"
    COLLECTION_NAME = "hostel_policies"
    SIMILARITY_THRESHOLD = 0.6
    
    TOP_K_RESULTS = 3
    
    LLM_MODEL = "gemini-1.5-flash"
    temperature = 0.3
    
    SUPPORTED_LANGUAGES = ["en", "hi","ta","te"]
    DEFAULT_LANGUAGE = "en"       