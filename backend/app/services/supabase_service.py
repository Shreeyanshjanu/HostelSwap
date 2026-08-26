"""
app/services/supabase_service.py
---------------------------------
Singleton Supabase client using the SERVICE_ROLE_KEY.
This key bypasses RLS — never send it to Flutter.
"""

import logging
from supabase import create_client, Client
from app.core.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

_supabase_client: Client | None = None


def get_supabase() -> Client:
    """Return the singleton Supabase admin client (FastAPI dependency)."""
    global _supabase_client
    if _supabase_client is None:
        logger.info("Initialising Supabase client...")
        _supabase_client = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY)
        logger.info("Supabase client ready.")
    return _supabase_client
