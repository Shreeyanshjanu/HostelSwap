"""
app/main.py — HostelSwap FastAPI application entry point.
Merges the original RAG endpoints with the full backend implementation.
"""
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import auth, requests, interests, contacts, chat
from app.scheduler.jobs import start_scheduler, stop_scheduler

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("HostelSwap Backend starting up...")
    start_scheduler()
    yield
    logger.info("HostelSwap Backend shutting down...")
    stop_scheduler()


app = FastAPI(
    title="HostelSwap Backend",
    description="API for the LPU Hostel Mutual-Swap platform",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount all routers
app.include_router(auth.router)
app.include_router(requests.router)
app.include_router(interests.router)
app.include_router(contacts.router)
app.include_router(chat.router)


@app.get("/health", tags=["health"])
async def health():
    return {"status": "ok", "service": "HostelSwap Backend"}


# Legacy endpoint — kept for backward compat
@app.get("/", tags=["health"])
async def root():
    return {"status": "ok", "service": "HostelSwap Backend"}
