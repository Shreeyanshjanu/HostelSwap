import os
from typing import List, Dict, Tuple
import chromadb
from chromadb.config import Settings
from rag.embedding import EmbeddingGenerator


class VectorStore:
    def __init__(self,collection_name:str="hostel_policies",persist_path:str="rag/chroma_db"):
        self.embedding_generator = EmbeddingGenerator()
        self.collection_name = collection_name
        
        self.client = chromadb.Client(Settings(
            chroma_db_impl="duckdb+parquet",
            persist_directory=persist_path
        ))
        
        self.collection = self.client.get_or_create_collection(
            name=collection_name,
            metadata={"hnsw:space": "cosine"}
        )
    
    def add_documents(self, chunks: List[Dict[str, str]]) -> None:
        """Add document chunks to vector store."""
        if not chunks:
            return
        
        texts = [chunk["text"] for chunk in chunks]
        ids = [f"chunk_{i}" for i, _ in enumerate(chunks)]
        
        # Generate embeddings
        embeddings = self.embedding_generator.encode(texts)
        
        # Add to ChromaDB
        self.collection.add(
            documents=texts,
            embeddings=embeddings,
            ids=ids,
            metadatas=[{"source": "hostel_policy.pdf", "index": i} for i in range(len(chunks))]
        )
        
    def search(self, query: str, top_k: int = 3) -> List[Dict[str, any]]:
        """Search for similar chunks."""
        query_embedding = self.embedding_generator.encode_query(query)
        
        results = self.collection.query(
            query_embeddings=[query_embedding],
            n_results=top_k
        )
        
        if not results['documents']:
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
        # Delete and recreate collection
        self.client.delete_collection(self.collection_name)
        self.collection = self.client.get_or_create_collection(
            name=self.collection_name,
            metadata={"hnsw:space": "cosine"}
        )
        

    