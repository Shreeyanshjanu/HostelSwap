# app/rag/pipeline.py

import os
import logging
from typing import Dict, Any
from dotenv import load_dotenv
from .config import RAGConfig
from .document_loader import DocumentLoader
from .vector_store import VectorStore
from .llm_handler import LLMHandler

load_dotenv()


class RAGPipeline:
    """End-to-end RAG pipeline orchestrator."""

    def __init__(self):
        self.config = RAGConfig()

        # Initialize components
        self.doc_loader = DocumentLoader(
            chunk_size=self.config.CHUNK_SIZE,
            overlap=self.config.CHUNK_OVERLAP
        )

        self.vector_store = VectorStore(
            collection_name=self.config.COLLECTION_NAME,
            persist_path=self.config.CHROMA_DB_PATH
        )

        # Azure OpenAI v1 configuration
        azure_api_key = os.getenv("AZURE_OPENAI_API_KEY")
        azure_endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
        azure_deployment = os.getenv("AZURE_OPENAI_DEPLOYMENT")

        if not azure_api_key or not azure_endpoint or not azure_deployment:
            logging.warning(
                "Azure OpenAI config incomplete — check .env for "
                "AZURE_OPENAI_API_KEY, AZURE_OPENAI_ENDPOINT, "
                "AZURE_OPENAI_DEPLOYMENT"
            )

            azure_api_key = "dummy-key"

        self.llm = LLMHandler(
            api_key=azure_api_key,
            azure_endpoint=azure_endpoint,
            azure_deployment=azure_deployment,
        )

        # Load documents if vector store is empty
        if self.vector_store.count() == 0:
            self._load_documents()

    def _load_documents(self):
        """Load documents into vector store."""
        pdf_path = os.getenv(
            "HOSTEL_POLICY_PDF",
            "./docs/hostel_policy.pdf"
        )

        if not os.path.exists(pdf_path):
            logging.warning(
                f"PDF not found at {pdf_path}. Using sample data."
            )
            self._load_sample_data()
            return

        try:
            chunks = self.doc_loader.load_and_chunk(pdf_path)
            self.vector_store.add_documents(chunks)

            logging.info(
                f"Loaded {len(chunks)} chunks from PDF"
            )

        except Exception as e:
            logging.error(
                f"Error loading documents: {str(e)}"
            )
            self._load_sample_data()

    def _load_sample_data(self):
        """Load sample data for testing."""

        sample_chunks = [
            {
                "text": (
                    "Hostel shift deadline is September 15th each year. "
                    "Students must submit the mutual transfer form before this date."
                ),
                "index": 0
            },
            {
                "text": (
                    "Students must have completed one semester to be eligible "
                    "for hostel transfer. The request must be submitted through "
                    "the student portal."
                ),
                "index": 1
            },
            {
                "text": (
                    "Contact the hostel office for any queries regarding room "
                    "allocation, fee adjustment, or transfer procedures."
                ),
                "index": 2
            },
            {
                "text": (
                    "Required documents for hostel transfer: Mutual consent form "
                    "signed by both students, No-dues certificate from current "
                    "hostel, Fee adjustment receipt."
                ),
                "index": 3
            },
        ]

        self.vector_store.add_documents(sample_chunks)

        logging.info(
            "Loaded sample data for testing"
        )

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

        try:
            # Detect language
            lang = self.llm.detect_language(query)

            # Search vector store
            results = self.vector_store.search(
                query,
                top_k=self.config.TOP_K_RESULTS
            )

            # Check confidence
            confidence = 0.0

            if results and results[0].get("score") is not None:
                # ChromaDB returns distance (lower = more similar)
                confidence = 1 - results[0]["score"] / 2

            should_escalate = (
                confidence < self.config.SIMILARITY_THRESHOLD
                or len(results) == 0
            )

            if should_escalate:
                return {
                    "answer": (
                        "I'm not confident about this. Please contact "
                        "the Hostel Office directly for assistance."
                    ),
                    "source": None,
                    "confidence": confidence,
                    "should_escalate": True,
                    "language": lang
                }

            # Generate answer
            answer, source = self.llm.generate_rag_answer(
                query,
                results
            )

            # Translate if needed
            if (
                lang != "en"
                and lang in self.config.SUPPORTED_LANGUAGES
            ):
                answer = self.llm.translate_response(
                    answer,
                    lang
                )

            return {
                "answer": answer,
                "source": source,
                "confidence": confidence,
                "should_escalate": False,
                "language": lang
            }

        except Exception as e:
            logging.error(
                f"RAG query error: {str(e)}"
            )

            return {
                "answer": f"Error processing query: {str(e)}",
                "source": None,
                "confidence": 0.0,
                "should_escalate": True,
                "language": "en"
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