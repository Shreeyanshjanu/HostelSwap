from pydantic import BaseModel
from typing import Optional

class ShowContactBody(BaseModel):
    request_id: str
    applicant_id: str

class FinalizeBody(BaseModel):
    request_id: str
    applicant_id: str

class FinalizationOut(BaseModel):
    id: str
    request_id: str
    requester_id: str
    applicant_id: str
    initiated_at: Optional[str] = None
    expires_at: Optional[str] = None
    is_completed: bool = False
