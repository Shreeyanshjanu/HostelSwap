from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from rag.pipeline import RAGPipeline

rag = RAGPipeline()


class RAGQueryRequest(BaseModel):
    query: str
    
class RAGQueryResponse(BaseModel):
    answer: str
    source: str | None = None
    confidence: float
    should_escalate: bool
    language: str
    
@app.post("/rag/query", response_model=RAGQueryResponse)
async def rag_query(request: RAGQueryRequest):
    """
    Query the RAG pipeline for hostel policy questions.
    """
    try:
        result = rag.process_query(request.query)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/rag/ingest")
async def ingest_documents():
    """
    Force re-ingestion of documents.
    (Useful for testing/updating documents)
    """
    try:
        # Clear existing collection
        rag.vector_store.clear()
        # Re-load documents
        rag._load_documents()
        return {"status": "success", "message": "Documents re-ingested"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))