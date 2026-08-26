"""app/api/chat.py — AI chatbot + RAG query endpoints."""
import logging
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, HTTPException
from supabase import Client
from app.services.supabase_service import get_supabase
from app.core.security import get_current_user
from app.core.hostels import get_hostels_for_gender, is_hostel_valid_for_gender, is_valid_hostel, is_valid_seater
from app.core.config import get_settings
from app.rag.pipeline import RAGPipeline
from app.rag.llm_handler import LLMHandler
from app.schemas.chat import ChatMessage, ChatResponse, RAGQueryBody, RAGQueryResponse
import os, json

logger = logging.getLogger(__name__)
router = APIRouter(tags=["chat"])
settings = get_settings()

_rag_pipeline: RAGPipeline | None = None
_llm: LLMHandler | None = None


def _get_rag() -> RAGPipeline:
    global _rag_pipeline
    if _rag_pipeline is None:
        _rag_pipeline = RAGPipeline()
    return _rag_pipeline


def _get_llm() -> LLMHandler:
    global _llm
    if _llm is None:
        provider = settings.LLM_PROVIDER
        if provider == "groq":
            _llm = LLMHandler(api_key=settings.GROQ_API_KEY, model_name=settings.GROQ_MODEL, provider="groq")
        else:
            _llm = LLMHandler(api_key=settings.GEMINI_API_KEY, model_name=settings.GEMINI_MODEL, provider="gemini")
    return _llm


@router.post("/chat", response_model=ChatResponse)
async def chat(body: ChatMessage, current_user: dict = Depends(get_current_user), db: Client = Depends(get_supabase)):
    college_id = current_user["sub"]
    gender = current_user["gender"]
    llm = _get_llm()
    rag = _get_rag()
    intent = llm.classify_intent(body.message)

    if intent == "swap_request":
        valid_hostels = get_hostels_for_gender(gender)
        parsed = llm.parse_swap_request(body.message, gender, valid_hostels)
        if "error" in parsed:
            return ChatResponse(intent=intent, reply="I could not extract your swap details. Please try: 'I have BH-2 3-seater non-AC, want BH-1 2-seater AC'", parsed_data=None)
        errors = []
        for field in ["current_hostel", "desired_hostel"]:
            h = parsed.get(field)
            if not h or not is_valid_hostel(h):
                errors.append(f"{field} '{h}' is not recognised.")
            elif not is_hostel_valid_for_gender(h, gender):
                errors.append(f"{field} '{h}' is not valid for your gender.")
        for field in ["current_seater"]:
            s = parsed.get(field)
            if s and not is_valid_seater(int(s)):
                errors.append(f"{field} must be 2, 3, 4, or 5.")
        if errors:
            return ChatResponse(intent=intent, reply=f"Please check: {'; '.join(errors)}", parsed_data=parsed)
        expires_at = (datetime.now(timezone.utc) + timedelta(days=settings.REQUEST_EXPIRY_DAYS)).isoformat()
        active = db.from_("requests").select("id", count="exact").eq("user_id", college_id).eq("status", "active").execute()
        if (active.count or 0) >= settings.MAX_ACTIVE_REQUESTS:
            return ChatResponse(intent=intent, reply=f"You already have {settings.MAX_ACTIVE_REQUESTS} active requests. Please withdraw one first.", parsed_data=parsed)
        payload = {**parsed, "user_id": college_id, "gender": gender, "status": "active", "expires_at": expires_at}
        result = db.from_("requests").insert(payload).select().single().execute()
        return ChatResponse(intent=intent, reply=f"Done! Your swap request has been posted. Students in {parsed.get('desired_hostel')} will see it.", parsed_data=parsed, request_created=True, request_id=result.data["id"])

    elif intent == "policy_query":
        result = rag.process_query(body.message)
        return ChatResponse(intent=intent, reply=result["answer"])

    else:
        return ChatResponse(intent="general", reply="I can help you post a hostel swap request or answer questions about hostel policies. What would you like to do?")


@router.post("/rag-query", response_model=RAGQueryResponse)
async def rag_query(body: RAGQueryBody, current_user: dict = Depends(get_current_user)):
    rag = _get_rag()
    result = rag.process_query(body.query)
    return RAGQueryResponse(**result)
