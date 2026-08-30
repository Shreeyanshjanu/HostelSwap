# app/rag/document_loader.py

import os
import re
from typing import List, Dict
from pypdf import PdfReader

class DocumentLoader:
    """Loads and chunks documents for RAG pipeline."""
    
    def __init__(self, chunk_size: int = 500, overlap: int = 50):
        self.chunk_size = chunk_size
        self.overlap = overlap
    
    def load_pdf(self, pdf_path: str) -> str:
        """Extract text from PDF file."""
        if not os.path.exists(pdf_path):
            raise FileNotFoundError(f"PDF not found: {pdf_path}")
        
        text = ""
        with open(pdf_path, 'rb') as file:
            reader = PdfReader(file)
            for page in reader.pages:
                page_text = page.extract_text()
                if page_text:
                    text += page_text + "\n"
        
        return self._clean_text(text)
    
    def _clean_text(self, text: str) -> str:
        """Clean extracted text."""
        # Remove extra whitespace
        text = re.sub(r'\s+', ' ', text)
        # Remove page numbers
        text = re.sub(r'Page \d+', '', text)
        text = re.sub(r'\d+/\d+', '', text)
        # Remove repeated newlines
        text = re.sub(r'\n\s*\n', '\n\n', text)
        return text.strip()
    
    def chunk_text(self, text: str) -> List[Dict[str, str]]:
        """Split text into overlapping chunks."""
        words = text.split()
        chunks = []
        
        for i in range(0, len(words), self.chunk_size - self.overlap):
            chunk = ' '.join(words[i:i + self.chunk_size])
            if chunk.strip():
                chunks.append({
                    "text": chunk,
                    "index": len(chunks)
                })
        
        return chunks
    
    def load_and_chunk(self, pdf_path: str) -> List[Dict[str, str]]:
        """Complete pipeline: load PDF → clean → chunk."""
        text = self.load_pdf(pdf_path)
        return self.chunk_text(text)