"""app/api/auth.py — Authentication endpoints."""
import logging
from fastapi import APIRouter, Depends, HTTPException
from supabase import Client
from app.services.supabase_service import get_supabase
from app.core.security import create_access_token, get_current_user
from app.core.constants import ALL_GENDERS
from app.schemas.auth import LoginRequest, LoginResponse, FCMTokenRequest, UserProfile

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", response_model=LoginResponse)
async def login(body: LoginRequest, db: Client = Depends(get_supabase)):
    if body.gender not in ALL_GENDERS:
        raise HTTPException(400, detail=f"gender must be one of: {', '.join(sorted(ALL_GENDERS))}")
    resp = db.from_("users").select("*").eq("college_id", body.college_id).maybe_single().execute()
    if resp.data:
        user = resp.data
    else:
        insert = db.from_("users").insert({"college_id": body.college_id, "name": body.college_id, "gender": body.gender}).select().single().execute()
        user = insert.data
    token = create_access_token(user["college_id"], user["gender"])
    return LoginResponse(access_token=token, college_id=user["college_id"], gender=user["gender"], name=user.get("name"))


@router.post("/fcm-token", status_code=204)
async def update_fcm_token(body: FCMTokenRequest, current_user: dict = Depends(get_current_user), db: Client = Depends(get_supabase)):
    db.from_("users").update({"fcm_token": body.fcm_token}).eq("college_id", current_user["sub"]).execute()


@router.get("/me", response_model=UserProfile)
async def get_me(current_user: dict = Depends(get_current_user), db: Client = Depends(get_supabase)):
    resp = db.from_("users").select("college_id,name,gender,phone,created_at").eq("college_id", current_user["sub"]).maybe_single().execute()
    if not resp.data:
        raise HTTPException(404, "User not found")
    return UserProfile(**resp.data)
