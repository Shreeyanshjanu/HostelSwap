from pydantic import BaseModel, field_validator, model_validator
from typing import Optional
from app.core.hostels import is_valid_seater

class CreateRequestBody(BaseModel):
    current_hostel: str
    current_ac: bool
    current_seater: int
    desired_hostel: str
    desired_ac: Optional[bool] = None
    desired_seater: Optional[int] = None

    @field_validator("current_seater")
    @classmethod
    def current_seater_valid(cls, v):
        if not is_valid_seater(v):
            raise ValueError("current_seater must be 2, 3, 4, or 5")
        return v

    @field_validator("desired_seater")
    @classmethod
    def desired_seater_valid(cls, v):
        if v is not None and not is_valid_seater(v):
            raise ValueError("desired_seater must be 2, 3, 4, or 5 (or null for flexible)")
        return v

class WithdrawRequest(BaseModel):
    request_id: str

class RequestOut(BaseModel):
    id: str
    user_id: str
    current_hostel: str
    current_ac: bool
    current_seater: int
    desired_hostel: str
    desired_ac: Optional[bool] = None
    desired_seater: Optional[int] = None
    status: str
    gender: str
    created_at: Optional[str] = None
    expires_at: Optional[str] = None
