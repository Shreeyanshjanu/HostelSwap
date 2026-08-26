"""app/scheduler/jobs.py — Background cleanup jobs (APScheduler)."""
import logging
from datetime import datetime, timezone
from apscheduler.schedulers.asyncio import AsyncIOScheduler

logger = logging.getLogger(__name__)
scheduler = AsyncIOScheduler()


def expire_old_requests():
    try:
        from app.services.supabase_service import get_supabase
        db = get_supabase()
        now = datetime.now(timezone.utc).isoformat()
        result = db.from_("requests").update({"status": "expired"}).eq("status", "active").lt("expires_at", now).execute()
        logger.info(f"Expired old requests.")
    except Exception as e:
        logger.error(f"Error in expire_old_requests: {e}")


def expire_finalizations():
    try:
        from app.services.supabase_service import get_supabase
        db = get_supabase()
        now = datetime.now(timezone.utc).isoformat()
        db.from_("finalizations").update({"is_completed": False}).eq("is_completed", False).lt("expires_at", now).execute()
        logger.info("Checked expired finalizations.")
    except Exception as e:
        logger.error(f"Error in expire_finalizations: {e}")


def start_scheduler():
    scheduler.add_job(expire_old_requests, "interval", hours=1, id="expire_requests", replace_existing=True)
    scheduler.add_job(expire_finalizations, "interval", minutes=15, id="expire_finalizations", replace_existing=True)
    scheduler.start()
    logger.info("APScheduler started with 2 jobs.")


def stop_scheduler():
    scheduler.shutdown()
    logger.info("APScheduler stopped.")
