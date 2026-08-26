"""app/models/interest_model.py — Pydantic model for interest records."""
from pydantic import BaseModel
from typing import Optional

class InterestModel(BaseModel):
    id: Optional[str] = None
    request_id: str
    applicant_id: str
    message: Optional[str] = None
    status: str = "pending"
    created_at: Optional[str] = None
