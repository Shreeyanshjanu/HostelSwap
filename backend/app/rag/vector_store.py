"""
app/rag/vector_store.py
------------------------
ChromaDB persistent vector store.
Updated for ChromaDB >= 0.4 (PersistentClient replaces deprecated Settings API).
"""
import os
from typing import List, Dict, Any
import chromadb
from app.rag.embedding import EmbeddingGenerator


class VectorStore:
    def __init__(self, collection_name: str = "hostel_policies", persist_path: str = "./chroma_db"):
        self.embedding_generator = EmbeddingGenerator()
        self.collection_name = collection_name
        os.makedirs(persist_path, exist_ok=True)
        # PersistentClient is the correct API for ChromaDB >= 0.4
        self.client = chromadb.PersistentClient(path=persist_path)
        self.collection = self.client.get_or_create_collection(
            name=collection_name,
            metadata={"hnsw:space": "cosine"},
        )

    def add_documents(self, chunks: List[Dict[str, str]]) -> None:
        if not chunks:
            return
        texts = [chunk["text"] for chunk in chunks]
        ids = [f"chunk_{i}" for i in range(len(chunks))]
        embeddings = self.embedding_generator.encode(texts)
        self.collection.add(
            documents=texts,
            embeddings=embeddings,
            ids=ids,
            metadatas=[{"source": "hostel_policy.pdf", "index": i} for i in range(len(chunks))],
        )

    def search(self, query: str, top_k: int = 3) -> List[Dict[str, Any]]:
        query_embedding = self.embedding_generator.encode_query(query)
        results = self.collection.query(query_embeddings=[query_embedding], n_results=top_k)
        if not results["documents"]:
            return []
        return [
            {
                "text": results["documents"][0][i],
                "score": results["distances"][0][i] if results.get("distances") else None,
                "metadata": results["metadatas"][0][i] if results.get("metadatas") else {},
            }
            for i in range(len(results["documents"][0]))
        ]

    def count(self) -> int:
        return self.collection.count()

    def clear(self) -> None:
        self.client.delete_collection(self.collection_name)
        self.collection = self.client.get_or_create_collection(
            name=self.collection_name,
            metadata={"hnsw:space": "cosine"},
        )
