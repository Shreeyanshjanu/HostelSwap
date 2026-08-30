# backend/app/services/fcm_service.py

import os
import logging
from typing import Optional
import firebase_admin
from firebase_admin import credentials, messaging
from dotenv import load_dotenv

load_dotenv()

class FCMService:
    def __init__(self):
        self.initialized = False
        try:
            cred_path = os.getenv("FIREBASE_CREDENTIALS", "./firebase-credentials.json")
            if os.path.exists(cred_path):
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred)
                self.initialized = True
                logging.info("FCM initialized successfully")
            else:
                logging.warning("Firebase credentials not found. FCM disabled.")
        except Exception as e:
            logging.error(f"FCM initialization error: {str(e)}")
    
    def send_notification(self, token: str, title: str, body: str) -> bool:
        """Send a push notification."""
        if not self.initialized or not token:
            return False
        
        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                token=token,
            )
            
            response = messaging.send(message)
            logging.info(f"Notification sent: {response}")
            return True
            
        except Exception as e:
            logging.error(f"FCM send error: {str(e)}")
            return False