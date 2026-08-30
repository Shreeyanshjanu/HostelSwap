# app/rag/vector_store.py

import os
from typing import List, Dict, Any
import chromadb
from chromadb.config import Settings
from .embedding import EmbeddingGenerator

class VectorStore:
    """Manages ChromaDB vector storage and retrieval."""
    
    def __init__(self, collection_name: str = "hostel_policies", persist_path: str = "./chroma_db"):
        self.embedding_generator = EmbeddingGenerator()
        self.collection_name = collection_name
        
        # Ensure persist directory exists
        os.makedirs(persist_path, exist_ok=True)
        
        # Initialize ChromaDB client with persistence
        self.client = chromadb.PersistentClient(
            path=persist_path
        )
        
        # Get or create collection
        self.collection = self.client.get_or_create_collection(
            name=collection_name,
            metadata={"hnsw:space": "cosine"}
        )
    
    def add_documents(self, chunks: List[Dict[str, str]]) -> None:
        """Add document chunks to vector store."""
        if not chunks:
            return
        
        texts = [chunk["text"] for chunk in chunks]
        ids = [f"chunk_{i}" for i in range(len(chunks))]
        
        # Generate embeddings
        embeddings = self.embedding_generator.encode(texts)
        
        # Add to ChromaDB
        self.collection.add(
            documents=texts,
            embeddings=embeddings,
            ids=ids,
            metadatas=[{"source": "hostel_policy.pdf", "index": i} for i in range(len(chunks))]
        )
    
    def search(self, query: str, top_k: int = 3) -> List[Dict[str, Any]]:
        """Search for similar chunks."""
        query_embedding = self.embedding_generator.encode_query(query)
        
        results = self.collection.query(
            query_embeddings=[query_embedding],
            n_results=top_k
        )
        
        if not results['documents'] or not results['documents'][0]:
            return []
        
        # Format results
        return [
            {
                "text": results['documents'][0][i],
                "score": results['distances'][0][i] if results.get('distances') else None,
                "metadata": results['metadatas'][0][i] if results.get('metadatas') else {}
            }
            for i in range(len(results['documents'][0]))
        ]
    
    def count(self) -> int:
        """Get total number of documents in collection."""
        return self.collection.count()
    
    def clear(self) -> None:
        """Clear all documents from collection."""
        try:
            self.client.delete_collection(self.collection_name)
        except:
            pass
        self.collection = self.client.get_or_create_collection(
            name=self.collection_name,
            metadata={"hnsw:space": "cosine"}
        )