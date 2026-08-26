"""app/api/requests.py — Swap request management endpoints."""
import logging
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, HTTPException
from supabase import Client
from app.services.supabase_service import get_supabase
from app.core.security import get_current_user
from app.core.hostels import is_hostel_valid_for_gender, is_valid_hostel
from app.core.config import get_settings
from app.schemas.requests import CreateRequestBody, WithdrawRequest, RequestOut

logger = logging.getLogger(__name__)
router = APIRouter(tags=["requests"])
settings = get_settings()


@router.post("/requests", response_model=RequestOut)
async def create_request(body: CreateRequestBody, current_user: dict = Depends(get_current_user), db: Client = Depends(get_supabase)):
    college_id = current_user["sub"]
    gender = current_user["gender"]
    for hostel, label in [(body.current_hostel, "current_hostel"), (body.desired_hostel, "desired_hostel")]:
        if not is_valid_hostel(hostel):
            raise HTTPException(400, f"{label} '{hostel}' is not a recognised hostel.")
        if not is_hostel_valid_for_gender(hostel, gender):
            raise HTTPException(400, f"{label} '{hostel}' is not a valid hostel for your gender.")
    active = db.from_("requests").select("id", count="exact").eq("user_id", college_id).eq("status", "active").execute()
    if (active.count or 0) >= settings.MAX_ACTIVE_REQUESTS:
        raise HTTPException(400, f"You already have {settings.MAX_ACTIVE_REQUESTS} active requests. Withdraw one first.")
    existing = db.from_("requests").select("id").eq("user_id", college_id).eq("current_hostel", body.current_hostel).eq("desired_hostel", body.desired_hostel).eq("status", "active").maybe_single().execute()
    if existing.data:
        raise HTTPException(409, "You already have an identical active request.")
    expires_at = (datetime.now(timezone.utc) + timedelta(days=settings.REQUEST_EXPIRY_DAYS)).isoformat()
    payload = {**body.model_dump(), "user_id": college_id, "gender": gender, "status": "active", "expires_at": expires_at}
    result = db.from_("requests").insert(payload).select().single().execute()
    return RequestOut(**result.data)


@router.get("/requests", response_model=list[RequestOut])
async def list_requests(current_user: dict = Depends(get_current_user), db: Client = Depends(get_supabase)):
    gender = current_user["gender"]
    resp = db.from_("requests").select("*").eq("status", "active").eq("gender", gender).order("created_at", desc=True).execute()
    return [RequestOut(**r) for r in (resp.data or [])]


@router.get("/requests/mine", response_model=list[RequestOut])
async def my_requests(current_user: dict = Depends(get_current_user), db: Client = Depends(get_supabase)):
    resp = db.from_("requests").select("*").eq("user_id", current_user["sub"]).order("created_at", desc=True).execute()
    return [RequestOut(**r) for r in (resp.data or [])]


@router.post("/withdraw-request", status_code=200)
async def withdraw_request(body: WithdrawRequest, current_user: dict = Depends(get_current_user), db: Client = Depends(get_supabase)):
    req = db.from_("requests").select("user_id,status").eq("id", body.request_id).maybe_single().execute()
    if not req.data:
        raise HTTPException(404, "Request not found.")
    if req.data["user_id"] != current_user["sub"]:
        raise HTTPException(403, "Not your request.")
    if req.data["status"] != "active":
        raise HTTPException(400, f"Request is already {req.data['status']}.")
    db.from_("requests").update({"status": "withdrawn"}).eq("id", body.request_id).execute()
    return {"message": "Request withdrawn successfully."}
