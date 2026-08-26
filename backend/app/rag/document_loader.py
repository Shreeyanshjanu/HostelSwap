"""
app/rag/document_loader.py
---------------------------
Loads and chunks the hostel policy PDF.
Uses pypdf (not PyPDF2 which is deprecated).
"""

import os, re
from typing import List, Dict
from pypdf import PdfReader


class DocumentLoader:
    def __init__(self, chunk_size: int = 500, overlap: int = 50):
        self.chunk_size = chunk_size
        self.overlap = overlap

    def load_pdf(self, pdf_path: str) -> str:
        if not os.path.exists(pdf_path):
            raise FileNotFoundError(f"PDF not found: {pdf_path}")
        text = ""
        reader = PdfReader(pdf_path)
        for page in reader.pages:
            page_text = page.extract_text()
            if page_text:
                text += page_text + "\n"
        return self._clean_text(text)

    def _clean_text(self, text: str) -> str:
        text = re.sub(r"\s+", " ", text)
        text = re.sub(r"Page \d+", "", text)
        text = re.sub(r"\n\s*\n", "\n\n", text)
        return text.strip()

    def chunk_text(self, text: str) -> List[Dict[str, str]]:
        words = text.split()
        chunks = []
        step = max(1, self.chunk_size - self.overlap)
        for i in range(0, len(words), step):
            chunk_words = words[i: i + self.chunk_size]
            chunk = " ".join(chunk_words)
            chunks.append({"text": chunk, "index": len(chunks)})
        return chunks

    def load_and_chunk(self, pdf_path: str) -> List[Dict[str, str]]:
        """Unified helper: load + chunk in one call."""
        text = self.load_pdf(pdf_path)
        return self.chunk_text(text)

    # Keep old method name for backward compat with any existing code
    def load_and_chunk_pdf(self, pdf_path: str) -> List[Dict[str, str]]:
        return self.load_and_chunk(pdf_path)
