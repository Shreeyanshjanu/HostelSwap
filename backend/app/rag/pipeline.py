import os
import logging
from typing import Tuple, Dict, Any
from rag.config import RAGConfig
from rag.document_loader import DocumentLoader
from rag.vector_store import VectorStore
from rag.llm_handler import LLMHandler

class RAGPipeline:
    """End-to-end RAG pipeline orchestrator."""
    
    def __init__(self):
        self.config = RAGConfig()
        self.doc_loader = DocumentLoader(
            chunk_size=self.config.CHUNK_SIZE,
            overlap=self.config.CHUNK_OVERLAP
        )
        self.vector_store = VectorStore(
            collection_name=self.config.COLLECTION_NAME,
            persist_path=self.config.CHROMA_DB_PATH
        )
        self.llm = LLMHandler(
            api_key=os.getenv("GEMINI_API_KEY"),
            model_name=self.config.LLM_MODEL
        )
        
        # Load documents if vector store is empty
        if self.vector_store.count() == 0:
            self._load_documents()
    
    def _load_documents(self):
        """Load documents into vector store."""
        pdf_path = os.getenv("HOSTEL_POLICY_PDF", "./docs/hostel_policy.pdf")
        
        if not os.path.exists(pdf_path):
            logging.warning(f"PDF not found at {pdf_path}. Using sample data.")
            self._load_sample_data()
            return
        
        try:
            chunks = self.doc_loader.load_and_chunk(pdf_path)
            self.vector_store.add_documents(chunks)
            logging.info(f"Loaded {len(chunks)} chunks from PDF")
        except Exception as e:
            logging.error(f"Error loading documents: {str(e)}")
            self._load_sample_data()
            
    def _load_sample_data(self):
        """Load sample data for testing."""
        sample_chunks = [
            {"text": "Hostel shift deadline is September 15th each year.", "index": 0},
            {"text": "Students must have completed one semester to be eligible for transfer.", "index": 1},
            {"text": "Contact the hostel office for any queries regarding room allocation.", "index": 2},
        ]
        self.vector_store.add_documents(sample_chunks)
        logging.info("Loaded sample data for testing")
    
    def process_query(self, query: str) -> Dict[str, Any]:
        """
        Process a user query through the RAG pipeline.
        
        Returns:
            {
                "answer": str,
                "source": str or None,
                "confidence": float,
                "should_escalate": bool,
                "language": str
            }
        """
        # Detect language
        lang = self.llm.detect_language(query)
        
        # Search vector store
        results = self.vector_store.search(query, top_k=self.config.TOP_K_RESULTS)
        
        # Check confidence (using similarity scores)
        confidence = 0.0
        if results and results[0].get("score") is not None:
            # ChromaDB returns distance (lower = more similar)
            # Convert to similarity score (1 - distance)
            confidence = 1 - results[0]["score"] / 2  # Normalize to 0-1 range
        
        should_escalate = confidence < self.config.SIMILARITY_THRESHOLD or len(results) == 0
        
        if should_escalate:
            return {
                "answer": "I'm not confident about this. Please contact the Hostel Office directly for assistance.",
                "source": None,
                "confidence": confidence,
                "should_escalate": True,
                "language": lang
            }
        
        # Generate answer
        answer, source = self.llm.generate_rag_answer(query, results)
        
        # Translate if needed (and not English)
        if lang != "en" and lang in self.config.SUPPORTED_LANGUAGES:
            answer = self.llm.translate_response(answer, lang)
        
        return {
            "answer": answer,
            "source": source,
            "confidence": confidence,
            "should_escalate": False,
            "language": lang
        }
    
    def health_check(self) -> Dict[str, Any]:
        """Check if RAG pipeline is healthy."""
        return {
            "status": "healthy",
            "document_count": self.vector_store.count(),
            "collection_name": self.config.COLLECTION_NAME,
            "embedding_model": self.config.EMBEDDING_MODEL,
            "llm_model": self.config.LLM_MODEL
        }