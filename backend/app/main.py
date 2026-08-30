# backend/app/main.py

import os
import logging
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, Dict, Any, List
from datetime import datetime, timedelta
from dotenv import load_dotenv
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.interval import IntervalTrigger

# Import services
from app.services.supabase_service import SupabaseService
from app.services.fcm_service import FCMService
from app.rag.pipeline import RAGPipeline
from app.utils.validators import Validators
from app.models.request_model import RequestModel

load_dotenv()

# Initialize services
supabase_service = SupabaseService()
fcm_service = FCMService()
rag_pipeline = RAGPipeline()

# Initialize FastAPI
app = FastAPI(
    title="HostelSwap API",
    description="Backend API for HostelSwap - Hostel Room Swap Matchmaker",
    version="1.0.0"
)
# app/main.py

from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:62777",
        "http://127.0.0.1:62777",
        "https://slapstick-riverboat-bulb.ngrok-free.dev",
        "*",  # Keep for testing
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*", "ngrok-skip-browser-warning"],  # 🔥 Explicitly add this
    expose_headers=["*"],
)

# ============ Pydantic Models ============

class ChatRequest(BaseModel):
    user_id: str
    message: str

class RAGQueryRequest(BaseModel):
    query: str

class ShowContactRequest(BaseModel):
    request_id: str
    requester_id: str
    applicant_id: str

class FinalizeSwapRequest(BaseModel):
    request_id: str
    requester_id: str
    applicant_id: str

class WithdrawRequest(BaseModel):
    request_id: str

class ExpressInterestRequest(BaseModel):
    request_id: str
    applicant_id: str

class LoginRequest(BaseModel):
    college_id: str
    gender: str
    name: Optional[str] = None

class CreateRequestRequest(BaseModel):
    user_id: str
    current_hostel: str
    current_ac: bool
    current_seater: int
    desired_hostel: str
    desired_ac: Optional[bool] = None
    desired_seater: Optional[int] = None

# ============ Health Check ============

@app.get("/")
async def root():
    return {
        "message": "HostelSwap API",
        "status": "running",
        "version": "1.0.0"
    }

@app.get("/health")
async def health_check():
    rag_health = rag_pipeline.health_check()
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "rag": rag_health
    }

# ============ Auth Endpoints ============

@app.post("/auth/login")
async def login(request: LoginRequest):
    """
    Login or create user with college ID.
    """
    try:
        user = await supabase_service.get_user(request.college_id)
        
        if user:
            return {
                "status": "success",
                "user": user.to_dict(),
                "is_new": False
            }
        else:
            # Create new user
            new_user = await supabase_service.create_user(
                request.college_id,
                request.gender,
                request.name
            )
            return {
                "status": "success",
                "user": new_user.to_dict(),
                "is_new": True
            }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/auth/update-token")
async def update_token(college_id: str, fcm_token: str):
    """
    Update user's FCM token.
    """
    try:
        await supabase_service.update_user_token(college_id, fcm_token)
        return {"status": "success", "message": "Token updated"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ============ Request Endpoints ============

@app.get("/requests")
async def get_requests(
    hostel: Optional[str] = None,
    ac: Optional[bool] = None,
    seater: Optional[int] = None,
    gender: Optional[str] = None,
    user_id: Optional[str] = None
):
    """
    Get all active requests with filters.
    """
    try:
        requests = await supabase_service.get_requests(
            hostel=hostel,
            ac=ac,
            seater=seater,
            gender=gender,
            user_id=user_id
        )
        return {
            "status": "success",
            "requests": [r.to_dict() for r in requests]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/requests/my/{user_id}")
async def get_my_requests(user_id: str):
    """
    Get user's own requests.
    """
    try:
        requests = await supabase_service.get_user_requests(user_id)
        return {
            "status": "success",
            "requests": [r.to_dict() for r in requests]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/requests/create")
async def create_request(request: CreateRequestRequest):
    """
    Create a new swap request.
    """
    try:
        # Check if user has too many active requests
        active_requests = await supabase_service.get_user_requests(
            request.user_id, 
            status="active"
        )
        if len(active_requests) >= 5:
            raise HTTPException(
                status_code=400,
                detail="You already have 5 active requests. Please withdraw one before posting a new one."
            )
        
        # Validate data
        data = request.dict()
        data['status'] = 'active'
        
        # Create request
        new_request = await supabase_service.create_request(data)
        
        return {
            "status": "success",
            "message": "Request created successfully",
            "request": new_request.to_dict()
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/requests/withdraw")
async def withdraw_request(request: WithdrawRequest):
    """
    Withdraw a request.
    """
    try:
        await supabase_service.update_request_status(request.request_id, "withdrawn")
        return {
            "status": "success",
            "message": "Request withdrawn successfully"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ============ Interest Endpoints ============

@app.post("/interests/express")
async def express_interest(request: ExpressInterestRequest):
    """
    Express interest in a request.
    """
    try:
        # Check if already applied
        has_applied = await supabase_service.has_applied_to_request(
            request.request_id,
            request.applicant_id
        )
        if has_applied:
            raise HTTPException(
                status_code=400,
                detail="You have already expressed interest in this request"
            )
        
        # Express interest
        await supabase_service.express_interest(
            request.request_id,
            request.applicant_id
        )
        
        # Get requester's FCM token for notification
        req = await supabase_service.get_request(request.request_id)
        if req:
            requester = await supabase_service.get_user(req.user_id)
            if requester and requester.fcm_token:
                fcm_service.send_notification(
                    requester.fcm_token,
                    "New Interest! 🎯",
                    f"Someone is interested in your swap request!"
                )
        
        return {
            "status": "success",
            "message": "Interest expressed successfully"
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/interests/applicants/{request_id}")
async def get_applicants(request_id: str):
    """
    Get all applicants for a request.
    """
    try:
        applicants = await supabase_service.get_applicants(request_id)
        return {
            "status": "success",
            "applicants": [a.to_dict() for a in applicants]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ============ Chat/Contact Endpoints ============

@app.post("/show-contact")
async def show_contact(request: ShowContactRequest):
    """
    Reveal phone numbers to both parties after interest is expressed.
    """
    try:
        # Verify requester owns the request
        req = await supabase_service.get_request(request.request_id)
        if not req:
            raise HTTPException(status_code=404, detail="Request not found")
        
        if req.user_id != request.requester_id:
            raise HTTPException(
                status_code=403,
                detail="Only the requester can view contacts"
            )
        
        # Verify that the applicant has expressed interest
        has_applied = await supabase_service.has_applied_to_request(
            request.request_id,
            request.applicant_id
        )
        if not has_applied:
            raise HTTPException(
                status_code=400,
                detail="This applicant has not expressed interest"
            )
        
        # Get phone numbers
        requester = await supabase_service.get_user(request.requester_id)
        applicant = await supabase_service.get_user(request.applicant_id)
        
        # Log the unlock
        await supabase_service.log_chat_unlock(
            request.request_id,
            request.requester_id,
            request.applicant_id
        )
        
        return {
            "status": "success",
            "requester_phone": requester.phone if requester else None,
            "applicant_phone": applicant.phone if applicant else None,
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ============ Finalize Swap Endpoints ============

@app.post("/finalize-swap")
async def finalize_swap(request: FinalizeSwapRequest):
    """
    Finalize a swap between requester and selected applicant.
    """
    try:
        # Verify requester owns the request
        req = await supabase_service.get_request(request.request_id)
        if not req:
            raise HTTPException(status_code=404, detail="Request not found")
        
        if req.user_id != request.requester_id:
            raise HTTPException(
                status_code=403,
                detail="Only the requester can finalize the swap"
            )
        
        # Update request status
        await supabase_service.update_request_status(request.request_id, "matched")
        
        # Update interest status for selected applicant
        await supabase_service.update_interest_status_by_request(
            request.request_id,
            request.applicant_id,
            "accepted"
        )
        
        # Reject all other applicants
        await supabase_service.reject_all_other_interests(
            request.request_id,
            request.applicant_id
        )
        
        # Send notifications
        applicant = await supabase_service.get_user(request.applicant_id)
        if applicant and applicant.fcm_token:
            fcm_service.send_notification(
                applicant.fcm_token,
                "Swap Confirmed! 🎉",
                "You have been selected for a swap! Contact the requester to finalize details."
            )
        
        # Notify rejected applicants
        rejected = await supabase_service.get_rejected_applicants(request.request_id)
        for item in rejected:
            if item.get('users') and item['users'].get('fcm_token'):
                fcm_service.send_notification(
                    item['users']['fcm_token'],
                    "Request Fulfilled",
                    "The request you applied for has been fulfilled."
                )
        
        return {
            "status": "success",
            "message": "Swap finalized successfully"
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ============ RAG Endpoints ============

@app.post("/chat")
async def chat(request: ChatRequest):
    """
    Process chatbot messages.
    Classifies intent and routes to appropriate handler.
    """
    try:
        # Get user
        user = await supabase_service.get_user(request.user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Check if the message is about posting a request or asking a policy question
        intent = rag_pipeline.llm.classify_intent(request.message)
        
        if intent == "swap_request":
            # Parse swap request
            parsed_data = rag_pipeline.llm.parse_swap_request(request.message)
            
            if "error" in parsed_data:
                return {
                    "intent": "swap_request",
                    "message": "I couldn't understand your request. Please specify: current hostel, AC/Non-AC, seater type, and desired hostel.",
                    "parsed_data": None
                }
            
            # Validate parsed data
            is_valid, error_msg = Validators.validate_swap_data(parsed_data)
            if not is_valid:
                return {
                    "intent": "swap_request",
                    "message": f"I couldn't validate your request: {error_msg}",
                    "parsed_data": None
                }
            
            # Check if user has too many active requests
            active_requests = await supabase_service.get_user_requests(
                request.user_id,
                status="active"
            )
            if len(active_requests) >= 5:
                return {
                    "intent": "swap_request",
                    "message": "You already have 5 active requests. Please withdraw one before posting a new one.",
                    "parsed_data": None
                }
            
            # Save to database
            request_data = {
                "user_id": request.user_id,
                "current_hostel": parsed_data.get("current_hostel"),
                "current_ac": parsed_data.get("current_ac"),
                "current_seater": parsed_data.get("current_seater"),
                "desired_hostel": parsed_data.get("desired_hostel"),
                "desired_ac": parsed_data.get("desired_ac"),
                "desired_seater": parsed_data.get("desired_seater"),
                "status": "active"
            }
            
            new_request = await supabase_service.create_request(request_data)
            
            return {
                "intent": "swap_request",
                "parsed_data": parsed_data,
                "message": f"Request posted successfully! Your request for {parsed_data.get('desired_hostel')} is now live on the dashboard.",
                "request_id": new_request.id
            }
        
        elif intent == "policy_query":
            # Use RAG for policy questions
            result = rag_pipeline.process_query(request.message)
            return {
                "intent": "policy_query",
                "answer": result["answer"],
                "source": result["source"],
                "confidence": result["confidence"],
                "should_escalate": result["should_escalate"],
                "language": result["language"]
            }
        
        else:
            # 🔥 FIX: this used to return a hardcoded static string every single time,
            # regardless of what the student actually said. Now it actually asks
            # Gemini to generate a real, message-specific conversational reply.
            reply = rag_pipeline.llm.generate_general_reply(request.message)
            return {
                "intent": "general",
                "message": reply
            }
            
    except HTTPException:
        raise
    except Exception as e:
        logging.error(f"Chat error: {str(e)}")
        return {
            "intent": "error",
            "message": f"Error: {str(e)}"
        }

@app.post("/rag/query")
async def rag_query(request: RAGQueryRequest):
    """
    Direct RAG query for hostel policy questions.
    """
    try:
        result = rag_pipeline.process_query(request.query)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/rag/health")
async def rag_health():
    """Health check for RAG pipeline."""
    return rag_pipeline.health_check()

@app.post("/rag/ingest")
async def ingest_documents():
    """
    Force re-ingestion of documents.
    """
    try:
        rag_pipeline.vector_store.clear()
        rag_pipeline._load_documents()
        return {"status": "success", "message": "Documents re-ingested"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ============ Auto-Delete Scheduler ============

def delete_expired_requests():
    """Delete requests older than 5 days."""
    try:
        expiry_date = datetime.now() - timedelta(days=5)
        expired = supabase_service.get_expired_requests(expiry_date)
        
        for req in expired:
            supabase_service.delete_request(req["id"])
            logging.info(f"Deleted expired request: {req['id']}")
            
    except Exception as e:
        logging.error(f"Auto-delete error: {str(e)}")

# Initialize scheduler
scheduler = BackgroundScheduler()
scheduler.add_job(
    delete_expired_requests,
    trigger=IntervalTrigger(days=1),
    id='delete_expired_requests',
    replace_existing=True
)
scheduler.start()

# ============ Startup & Shutdown ============

@app.on_event("startup")
async def startup_event():
    logging.info("HostelSwap API started")
    logging.info("Auto-delete scheduler running")

@app.on_event("shutdown")
async def shutdown_event():
    scheduler.shutdown()
    logging.info("HostelSwap API stopped")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )