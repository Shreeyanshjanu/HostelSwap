# backend/app/models/interest_model.py

from datetime import datetime
from typing import Optional
from pydantic import BaseModel
import uuid
from .user_model import UserModel

class InterestModel(BaseModel):
    id: str = str(uuid.uuid4())
    request_id: str
    applicant_id: str
    status: str = 'pending'  # 'pending', 'accepted', 'rejected'
    created_at: datetime = datetime.now()
    applicant: Optional[UserModel] = None

    @classmethod
    def from_dict(cls, data: dict):
        if not data:
            return None
        
        applicant_data = data.get('users')
        applicant = UserModel.from_dict(applicant_data) if applicant_data else None
        
        return cls(
            id=data.get('id', str(uuid.uuid4())),
            request_id=data.get('request_id', ''),
            applicant_id=data.get('applicant_id', ''),
            status=data.get('status', 'pending'),
            created_at=datetime.fromisoformat(data.get('created_at', datetime.now().isoformat())),
            applicant=applicant
        )
    
    def to_dict(self) -> dict:
        return {
            'id': self.id,
            'request_id': self.request_id,
            'applicant_id': self.applicant_id,
            'status': self.status,
            'created_at': self.created_at.isoformat()
        }