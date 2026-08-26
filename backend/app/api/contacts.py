"""app/api/contacts.py — Contact unlock and finalization endpoints."""
import logging
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, HTTPException
from supabase import Client
from app.services.supabase_service import get_supabase
from app.services.fcm_service import send_notification
from app.core.security import get_current_user
from app.core.config import get_settings
from app.schemas.finalize import ShowContactBody, FinalizeBody, FinalizationOut

logger = logging.getLogger(__name__)
router = APIRouter(tags=["contacts"])
settings = get_settings()


@router.post("/show-contact")
async def show_contact(body: ShowContactBody, current_user: dict = Depends(get_current_user), db: Client = Depends(get_supabase)):
    college_id = current_user["sub"]
    req = db.from_("requests").select("user_id,status").eq("id", body.request_id).maybe_single().execute()
    if not req.data:
        raise HTTPException(404, "Request not found.")
    if req.data["user_id"] != college_id:
        raise HTTPException(403, "Only the request owner can unlock contacts.")
    interest = db.from_("interests").select("id").eq("request_id", body.request_id).eq("applicant_id", body.applicant_id).eq("status", "pending").maybe_single().execute()
    if not interest.data:
        raise HTTPException(404, "No pending interest from this applicant.")
    db.from_("chat_unlocks").insert({"request_id": body.request_id, "requester_id": college_id, "applicant_id": body.applicant_id}).execute()
    applicant_phone = db.from_("users").select("phone").eq("college_id", body.applicant_id).maybe_single().execute()
    requester_phone = db.from_("users").select("phone").eq("college_id", college_id).maybe_single().execute()
    await send_notification(body.applicant_id, "Contact Shared", "The request owner has unlocked your contact.", {"event": "contact_shared", "request_id": body.request_id}, db)
    return {"requester_phone": requester_phone.data.get("phone") if requester_phone.data else None, "applicant_phone": applicant_phone.data.get("phone") if applicant_phone.data else None}


@router.post("/finalize-swap", response_model=FinalizationOut)
async def finalize_swap(body: FinalizeBody, current_user: dict = Depends(get_current_user), db: Client = Depends(get_supabase)):
    college_id = current_user["sub"]
    req = db.from_("requests").select("user_id,status").eq("id", body.request_id).maybe_single().execute()
    if not req.data:
        raise HTTPException(404, "Request not found.")
    if req.data["user_id"] != college_id:
        raise HTTPException(403, "Only the request owner can initiate finalization.")
    if req.data["status"] != "active":
        raise HTTPException(400, "Request is not active.")
    pending = db.from_("finalizations").select("id").eq("request_id", body.request_id).eq("is_completed", False).maybe_single().execute()
    if pending.data:
        raise HTTPException(409, "A finalization is already pending for this request.")
    expires_at = (datetime.now(timezone.utc) + timedelta(hours=settings.FINALIZATION_HOURS)).isoformat()
    result = db.from_("finalizations").insert({"request_id": body.request_id, "requester_id": college_id, "applicant_id": body.applicant_id, "expires_at": expires_at, "is_completed": False}).select().single().execute()
    await send_notification(body.applicant_id, "Swap Proposed!", f"Someone wants to finalise a swap with you. You have {settings.FINALIZATION_HOURS}h to accept.", {"event": "finalize_proposed", "finalization_id": result.data["id"]}, db)
    return FinalizationOut(**result.data)


@router.post("/accept-swap/{finalization_id}")
async def accept_swap(finalization_id: str, current_user: dict = Depends(get_current_user), db: Client = Depends(get_supabase)):
    college_id = current_user["sub"]
    fin = db.from_("finalizations").select("*").eq("id", finalization_id).maybe_single().execute()
    if not fin.data:
        raise HTTPException(404, "Finalization not found.")
    if fin.data["applicant_id"] != college_id:
        raise HTTPException(403, "Only the applicant can accept a finalization.")
    if fin.data["is_completed"]:
        raise HTTPException(400, "Already completed.")
    expires_at = datetime.fromisoformat(fin.data["expires_at"].replace("Z", "+00:00"))
    if datetime.now(timezone.utc) > expires_at:
        raise HTTPException(400, "Finalization window has expired.")
    db.from_("finalizations").update({"is_completed": True}).eq("id", finalization_id).execute()
    db.from_("requests").update({"status": "matched"}).eq("id", fin.data["request_id"]).execute()
    await send_notification(fin.data["requester_id"], "Swap Accepted!", "Your swap has been accepted. Congratulations!", {"event": "swap_accepted", "request_id": fin.data["request_id"]}, db)
    return {"message": "Swap accepted successfully!"}
