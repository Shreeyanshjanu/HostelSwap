"""app/rag/embedding.py — Singleton sentence-transformer embedding model."""
from typing import Union, List
from sentence_transformers import SentenceTransformer

_model_instance = None

def get_embedding_model(model_name: str = "all-MiniLM-L6-v2") -> SentenceTransformer:
    global _model_instance
    if _model_instance is None:
        _model_instance = SentenceTransformer(model_name)
    return _model_instance


class EmbeddingGenerator:
    def __init__(self, model_name: str = "all-MiniLM-L6-v2"):
        self.model = get_embedding_model(model_name)
        self.embedding_dimension = self.model.get_embedding_dimension()

    def encode(self, texts: Union[str, List[str]]) -> List[List[float]]:
        if isinstance(texts, str):   # was: instance (typo bug)
            texts = [texts]
        embeddings = self.model.encode(texts, convert_to_tensor=False)
        return embeddings.tolist()

    def encode_query(self, query: str) -> List[float]:
        return self.encode(query)[0]

