from pydantic import BaseModel
from typing import Optional, Any

class ChatMessage(BaseModel):
    message: str
    conversation_id: Optional[str] = None

class ChatResponse(BaseModel):
    intent: str
    reply: str
    parsed_data: Optional[Any] = None
    request_created: bool = False
    request_id: Optional[str] = None

class RAGQueryBody(BaseModel):
    query: str

class RAGQueryResponse(BaseModel):
    answer: str
    source: Optional[str] = None
    confidence: float
    should_escalate: bool
    language: str
