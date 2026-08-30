# backend/models/user_model.py

from datetime import datetime
from typing import Optional
from pydantic import BaseModel

class UserModel(BaseModel):
    college_id: str
    name: str
    gender: str  # 'male', 'female', 'other'
    phone: Optional[str] = None
    fcm_token: Optional[str] = None
    created_at: datetime

    @classmethod
    def from_dict(cls, data: dict):
        return cls(
            college_id=data.get('college_id', ''),
            name=data.get('name', ''),
            gender=data.get('gender', ''),
            phone=data.get('phone'),
            fcm_token=data.get('fcm_token'),
            created_at=datetime.fromisoformat(data.get('created_at', datetime.now().isoformat()))
        )
    
    def to_dict(self) -> dict:
        return {
            'college_id': self.college_id,
            'name': self.name,
            'gender': self.gender,
            'phone': self.phone,
            'fcm_token': self.fcm_token,
            'created_at': self.created_at.isoformat()
        }