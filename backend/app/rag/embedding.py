from typing import List, Union
from sentence_transformers import SentenceTransformer


class EmbeddingGenerator:
    def __init__(self,model_name:str = "all-MiniLM-L6-v2"):
        self.model = SentenceTransformer(model_name)
        self.embedding_dimension = self.model.get_sentence_embedding_dimension()
        
    def encode(self,texts:Union[str,List[str]])-> List[List[float]]:
        if instance(texts,str):
            texts = [texts]
            
        embeddings = self.model.encode(texts,convert_to_tensor=False)
        return embeddings.tolist()

    def encode_query(self,query:str)-> List[float]:
        return self.encode(query)[0]
    
    
    
    