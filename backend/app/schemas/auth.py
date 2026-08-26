from pydantic import BaseModel, field_validator
from typing import Optional
from app.core.constants import ALL_GENDERS

class LoginRequest(BaseModel):
    college_id: str
    gender: str

    @field_validator("college_id")
    @classmethod
    def college_id_must_be_nonempty(cls, v):
        if not v or not v.strip():
            raise ValueError("college_id is required")
        return v.strip()

    @field_validator("gender")
    @classmethod
    def gender_must_be_valid(cls, v):
        if v not in ALL_GENDERS:
            raise ValueError(f"gender must be one of: {', '.join(sorted(ALL_GENDERS))}")
        return v

class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    college_id: str
    gender: str
    name: Optional[str] = None

class FCMTokenRequest(BaseModel):
    fcm_token: str

class UserProfile(BaseModel):
    college_id: str
    name: Optional[str] = None
    gender: str
    phone: Optional[str] = None
    created_at: Optional[str] = None
