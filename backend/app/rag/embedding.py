# app/rag/embedding.py

from typing import List, Union
from sentence_transformers import SentenceTransformer

class EmbeddingGenerator:
    """Generate embeddings using sentence-transformers."""
    
    def __init__(self, model_name: str = "all-MiniLM-L6-v2"):
        self.model = SentenceTransformer(model_name)
        self.dimension = 384
    
    def encode(self, texts: Union[str, List[str]]) -> List[List[float]]:
        """Convert text(s) to embeddings."""
        if isinstance(texts, str):
            texts = [texts]
        
        embeddings = self.model.encode(texts, convert_to_tensor=False)
        return embeddings.tolist()
    
    def encode_query(self, query: str) -> List[float]:
        """Encode a single query for search."""
        return self.encode(query)[0]