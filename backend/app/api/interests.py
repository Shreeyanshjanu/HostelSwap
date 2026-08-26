"""app/api/interests.py — Interest / application endpoints."""
from fastapi import APIRouter, Depends, HTTPException
from supabase import Client
from app.services.supabase_service import get_supabase
from app.core.security import get_current_user
from app.schemas.interests import ExpressInterestBody, InterestOut

router = APIRouter(tags=["interests"])


@router.post("/interests", response_model=InterestOut)
async def express_interest(body: ExpressInterestBody, current_user: dict = Depends(get_current_user), db: Client = Depends(get_supabase)):
    college_id = current_user["sub"]
    req = db.from_("requests").select("user_id,status").eq("id", body.request_id).maybe_single().execute()
    if not req.data:
        raise HTTPException(404, "Request not found.")
    if req.data["status"] != "active":
        raise HTTPException(400, "This request is no longer active.")
    if req.data["user_id"] == college_id:
        raise HTTPException(400, "You cannot apply to your own request.")
    dup = db.from_("interests").select("id").eq("request_id", body.request_id).eq("applicant_id", college_id).maybe_single().execute()
    if dup.data:
        raise HTTPException(409, "You have already expressed interest in this request.")
    result = db.from_("interests").insert({"request_id": body.request_id, "applicant_id": college_id, "message": body.message, "status": "pending"}).select().single().execute()
    return InterestOut(**result.data)


@router.get("/interests/{request_id}", response_model=list[InterestOut])
async def get_interests(request_id: str, current_user: dict = Depends(get_current_user), db: Client = Depends(get_supabase)):
    req = db.from_("requests").select("user_id").eq("id", request_id).maybe_single().execute()
    if not req.data:
        raise HTTPException(404, "Request not found.")
    if req.data["user_id"] != current_user["sub"]:
        raise HTTPException(403, "Only the request owner can see applicants.")
    resp = db.from_("interests").select("*").eq("request_id", request_id).order("created_at", desc=True).execute()
    return [InterestOut(**i) for i in (resp.data or [])]
