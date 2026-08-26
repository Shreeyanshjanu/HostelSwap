import os
import re
from typing import List, Dict
import PyPDF2

class DocumentLoader:
    def __init__(self,chunk_size: int = 500,overlap:int = 50):
        self.chunk_size = chunk_size
        self.overlap = overlap
    
    def load_pdf(self,pdf_path:str) -> str:
        if not os.path.exists(pdf_path):
            raise FileNotFoundError(f"PDF file not found: {pdf_path}")  
        
        text = ""
        
        with open(pdf_path, "rb") as file:
            reader = PyPDF2.PdfReader(file)
            for page in reader.pages:
                page_text = page.extract_text()
                
                if page_text:
                    text += page_text + "\n"
                    
        return self._clean_text(text)
    
    def _clean_text(self,text:str) -> str:
        text = re.sub(r'\s+', ' ', text)
        text = re.sub(r'Page \d+', '', text)
        text = re.sub(r'\d+/\d+', '', text)
        text = re.sub(r'\n\s*\n', '\n\n', text)
        return text.strip()
    
    def chunk_text(self,text:str)-> List[Dict[str,str]]:
        words = text.split()
        chunks = []
         
        for i in range(0,len(words),self.chunk_size-self.overlap):
            
            chunks.append({
                "text":chunk,
                "index":len(chunks)
            })
        
        return chunks
    
    def load_and_chunk_pdf(self,pdf_path:str)-> List[Dict[str,str]]:
        text = self.load_pdf(pdf_path)
        return self.chunk_text(text)
            