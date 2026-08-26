"""app/models/user_model.py — Pydantic model for user data."""
from pydantic import BaseModel
from typing import Optional

class UserModel(BaseModel):
    college_id: str
    name: Optional[str] = None
    gender: str
    phone: Optional[str] = None
    fcm_token: Optional[str] = None
    created_at: Optional[str] = None
