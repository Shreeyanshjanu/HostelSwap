"""app/models/request_model.py — Pydantic model for swap requests."""
from pydantic import BaseModel
from typing import Optional

class RequestModel(BaseModel):
    id: Optional[str] = None
    user_id: str
    current_hostel: str
    current_ac: bool
    current_seater: int
    desired_hostel: str
    desired_ac: Optional[bool] = None
    desired_seater: Optional[int] = None
    status: str = "active"
    gender: str
    created_at: Optional[str] = None
    expires_at: Optional[str] = None
