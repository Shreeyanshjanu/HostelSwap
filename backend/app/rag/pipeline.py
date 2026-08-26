"""
app/rag/pipeline.py
--------------------
End-to-end RAG pipeline. Existing public API preserved.
"""
import os, logging
from typing import Dict, Any
from app.rag.config import RAGConfig
from app.rag.document_loader import DocumentLoader
from app.rag.vector_store import VectorStore
from app.rag.llm_handler import LLMHandler

logger = logging.getLogger(__name__)


class RAGPipeline:
    """End-to-end RAG pipeline orchestrator."""

    def __init__(self):
        self.config = RAGConfig()
        self.doc_loader = DocumentLoader(chunk_size=self.config.CHUNK_SIZE, overlap=self.config.CHUNK_OVERLAP)
        self.vector_store = VectorStore(
            collection_name=self.config.COLLECTION_NAME,
            persist_path=self.config.CHROMA_DB_PATH,
        )
        provider = os.getenv("LLM_PROVIDER", "gemini")
        if provider == "groq":
            api_key = os.getenv("GROQ_API_KEY", "")
            model = os.getenv("GROQ_MODEL", "llama-3.3-70b-versatile")
        else:
            api_key = os.getenv("GEMINI_API_KEY", "")
            model = os.getenv("GEMINI_MODEL", "gemini-2.0-flash")
        self.llm = LLMHandler(api_key=api_key, model_name=model, provider=provider)
        if self.vector_store.count() == 0:
            self._load_documents()

    def _load_documents(self):
        pdf_path = os.getenv("HOSTEL_POLICY_PDF", "./docs/hostel_policy.pdf")
        if not os.path.exists(pdf_path):
            logger.warning(f"PDF not found at {pdf_path}. Using sample data.")
            self._load_sample_data()
            return
        try:
            chunks = self.doc_loader.load_and_chunk(pdf_path)
            self.vector_store.add_documents(chunks)
            logger.info(f"Loaded {len(chunks)} chunks from PDF")
        except Exception as e:
            logger.error(f"Error loading documents: {e}")
            self._load_sample_data()

    def _load_sample_data(self):
        sample_chunks = [
            {"text": "Hostel shift deadline is September 15th each year.", "index": 0},
            {"text": "Students must have completed one semester to be eligible for transfer.", "index": 1},
            {"text": "Contact the hostel office for any queries regarding room allocation.", "index": 2},
        ]
        self.vector_store.add_documents(sample_chunks)
        logger.info("Loaded sample data for testing")

    def process_query(self, query: str) -> Dict[str, Any]:
        lang = self.llm.detect_language(query)
        results = self.vector_store.search(query, top_k=self.config.TOP_K_RESULTS)
        confidence = 0.0
        if results and results[0].get("score") is not None:
            confidence = max(0.0, 1 - results[0]["score"] / 2)
        should_escalate = confidence < self.config.SIMILARITY_THRESHOLD or len(results) == 0
        if should_escalate:
            return {"answer": "I'\''m not confident about this. Please contact the Hostel Office directly.", "source": None, "confidence": confidence, "should_escalate": True, "language": lang}
        answer, source = self.llm.generate_rag_answer(query, results)
        if lang != "en" and lang in self.config.SUPPORTED_LANGUAGES:
            answer = self.llm.translate_response(answer, lang)
        return {"answer": answer, "source": source, "confidence": confidence, "should_escalate": False, "language": lang}

    def health_check(self) -> Dict[str, Any]:
        return {"status": "healthy", "document_count": self.vector_store.count(), "collection_name": self.config.COLLECTION_NAME, "embedding_model": self.config.EMBEDDING_MODEL, "llm_model": self.config.LLM_MODEL}
