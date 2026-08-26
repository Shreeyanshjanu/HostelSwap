from pydantic import BaseModel
from typing import Optional

class ExpressInterestBody(BaseModel):
    request_id: str
    message: Optional[str] = None

class InterestOut(BaseModel):
    id: str
    request_id: str
    applicant_id: str
    message: Optional[str] = None
    status: str
    created_at: Optional[str] = None
