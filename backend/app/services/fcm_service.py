"""
app/services/fcm_service.py
-----------------------------
Firebase Cloud Messaging push notifications.
Gracefully disabled if FIREBASE_CREDENTIALS_PATH is not set or invalid.
"""

import logging
from supabase import Client

logger = logging.getLogger(__name__)
_firebase_initialised = False


def _init_firebase() -> bool:
    global _firebase_initialised
    if _firebase_initialised:
        return True
    try:
        import firebase_admin
        from firebase_admin import credentials
        from app.core.config import get_settings
        settings = get_settings()
        if not settings.FIREBASE_CREDENTIALS_PATH:
            return False
        if not firebase_admin._apps:
            cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
            firebase_admin.initialize_app(cred)
            logger.info("Firebase Admin SDK initialised.")
        _firebase_initialised = True
        return True
    except Exception as e:
        logger.warning(f"Firebase init failed (notifications disabled): {e}")
        return False


async def send_notification(college_id: str, title: str, body: str, data: dict, db: Client) -> None:
    """Send push notification to a student. Non-fatal if Firebase is not configured."""
    if not _init_firebase():
        return
    try:
        resp = db.from_("users").select("fcm_token").eq("college_id", college_id).maybe_single().execute()
        if not resp.data or not resp.data.get("fcm_token"):
            return
        from firebase_admin import messaging
        msg = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in data.items()},
            token=resp.data["fcm_token"],
            android=messaging.AndroidConfig(priority="high"),
        )
        messaging.send(msg)
        logger.info(f"Notification sent to {college_id}: {title}")
    except Exception as e:
        logger.warning(f"FCM notification failed for {college_id}: {e}")
