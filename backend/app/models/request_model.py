# backend/app/models/request_model.py

from datetime import datetime
from typing import Optional
from pydantic import BaseModel
import uuid

class RequestModel(BaseModel):
    id: str = str(uuid.uuid4())
    user_id: str
    current_hostel: str
    current_ac: bool
    current_seater: int
    desired_hostel: str
    desired_ac: Optional[bool] = None
    desired_seater: Optional[int] = None
    status: str = 'active'  # 'active', 'matched', 'withdrawn'
    created_at: datetime = datetime.now()
    has_applied: bool = False  # For frontend only

    @classmethod
    def from_dict(cls, data: dict):
        if not data:
            return None
        return cls(
            id=data.get('id', str(uuid.uuid4())),
            user_id=data.get('user_id', ''),
            current_hostel=data.get('current_hostel', ''),
            current_ac=data.get('current_ac', False),
            current_seater=data.get('current_seater', 2),
            desired_hostel=data.get('desired_hostel', ''),
            desired_ac=data.get('desired_ac'),
            desired_seater=data.get('desired_seater'),
            status=data.get('status', 'active'),
            created_at=datetime.fromisoformat(data.get('created_at', datetime.now().isoformat()))
        )
    
    def to_dict(self) -> dict:
        return {
            'id': self.id,
            'user_id': self.user_id,
            'current_hostel': self.current_hostel,
            'current_ac': self.current_ac,
            'current_seater': self.current_seater,
            'desired_hostel': self.desired_hostel,
            'desired_ac': self.desired_ac,
            'desired_seater': self.desired_seater,
            'status': self.status,
            'created_at': self.created_at.isoformat()
        }
    
    @property
    def room_display(self) -> str:
        return f"{self.current_hostel} | {'AC' if self.current_ac else 'Non-AC'} | {self.current_seater}-Seater"
    
    @property
    def desired_display(self) -> str:
        result = self.desired_hostel
        if self.desired_ac is not None:
            result += f" | {'AC' if self.desired_ac else 'Non-AC'}"
        if self.desired_seater is not None:
            result += f" | {self.desired_seater}-Seater"
        return result