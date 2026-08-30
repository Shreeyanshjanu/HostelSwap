# backend/app/services/supabase_service.py

from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from app.database import supabase
from app.models.user_model import UserModel
from app.models.request_model import RequestModel
from app.models.interest_model import InterestModel

# Hostel Constants
BOYS_HOSTELS = ["BH-1", "BH-2", "BH-3"]
GIRLS_HOSTELS = ["GH-1", "GH-2", "GH-3"]
ALL_HOSTELS = BOYS_HOSTELS + GIRLS_HOSTELS
SEATER_TYPES = [2, 3, 4, 5]

class SupabaseService:
    
    # ============ USERS ============
    
    async def get_user(self, college_id: str) -> Optional[UserModel]:
        """Get user by college ID."""
        try:
            response = supabase.table('users').select('*').eq('college_id', college_id).execute()
            if response.data:
                return UserModel.from_dict(response.data[0])
            return None
        except Exception as e:
            print(f"Error getting user: {e}")
            return None
    
    async def create_user(self, college_id: str, gender: str, name: str = None) -> UserModel:
        """Create a new user."""
        try:
            data = {
                'college_id': college_id,
                'name': name or college_id,
                'gender': gender
            }
            response = supabase.table('users').insert(data).execute()
            return UserModel.from_dict(response.data[0])
        except Exception as e:
            raise Exception(f"Failed to create user: {e}")
    
    async def update_user(self, college_id: str, data: dict) -> Optional[UserModel]:
        """Update user details."""
        try:
            response = supabase.table('users').update(data).eq('college_id', college_id).execute()
            if response.data:
                return UserModel.from_dict(response.data[0])
            return None
        except Exception as e:
            raise Exception(f"Failed to update user: {e}")
    
    async def update_user_token(self, college_id: str, fcm_token: str) -> None:
        """Update user's FCM token."""
        try:
            supabase.table('users').update({'fcm_token': fcm_token}).eq('college_id', college_id).execute()
        except Exception as e:
            raise Exception(f"Failed to update token: {e}")
    
    # ============ REQUESTS ============
    
    async def get_requests(
        self,
        hostel: Optional[str] = None,
        ac: Optional[bool] = None,
        seater: Optional[int] = None,
        gender: Optional[str] = None,
        user_id: Optional[str] = None
    ) -> List[RequestModel]:
        """Get all active requests with filters."""
        try:
            query = supabase.table('requests').select('*').eq('status', 'active')
            
            # Gender filter
            if gender == 'male':
                query = query.in_('desired_hostel', BOYS_HOSTELS)
            elif gender == 'female':
                query = query.in_('desired_hostel', GIRLS_HOSTELS)
            
            # Additional filters
            if hostel:
                query = query.eq('desired_hostel', hostel)
            if ac is not None:
                query = query.eq('desired_ac', ac)
            if seater:
                query = query.eq('desired_seater', seater)
            
            response = query.order('created_at', desc=True).execute()
            
            requests = [RequestModel.from_dict(item) for item in response.data]
            
            # Check if user has applied to each request
            if user_id:
                for req in requests:
                    has_applied = await self.has_applied_to_request(req.id, user_id)
                    req.has_applied = has_applied
            
            return requests
        except Exception as e:
            raise Exception(f"Failed to get requests: {e}")
    
    async def get_user_requests(self, user_id: str, status: Optional[str] = None) -> List[RequestModel]:
        """Get requests by user."""
        try:
            query = supabase.table('requests').select('*').eq('user_id', user_id)
            if status:
                query = query.eq('status', status)
            response = query.order('created_at', desc=True).execute()
            return [RequestModel.from_dict(item) for item in response.data]
        except Exception as e:
            raise Exception(f"Failed to get user requests: {e}")
    
    async def get_request(self, request_id: str) -> Optional[RequestModel]:
        """Get single request by ID."""
        try:
            response = supabase.table('requests').select('*').eq('id', request_id).execute()
            if response.data:
                return RequestModel.from_dict(response.data[0])
            return None
        except Exception as e:
            return None
    
    async def create_request(self, data: Dict[str, Any]) -> RequestModel:
        """Create a new request."""
        try:
            response = supabase.table('requests').insert(data).execute()
            return RequestModel.from_dict(response.data[0])
        except Exception as e:
            raise Exception(f"Failed to create request: {e}")
    
    async def update_request_status(self, request_id: str, status: str) -> None:
        """Update request status."""
        try:
            supabase.table('requests').update({'status': status}).eq('id', request_id).execute()
        except Exception as e:
            raise Exception(f"Failed to update request: {e}")
    
    async def delete_request(self, request_id: str) -> None:
        """Delete a request."""
        try:
            supabase.table('requests').delete().eq('id', request_id).execute()
        except Exception as e:
            raise Exception(f"Failed to delete request: {e}")
    
    async def get_expired_requests(self, expiry_date: datetime) -> List[Dict[str, Any]]:
        """Get expired active requests."""
        try:
            response = supabase.table('requests').select('id').eq('status', 'active').lt('created_at', expiry_date.isoformat()).execute()
            return response.data
        except Exception as e:
            return []
    
    # ============ INTERESTS ============
    
    async def express_interest(self, request_id: str, applicant_id: str) -> None:
        """Express interest in a request."""
        try:
            supabase.table('interests').insert({
                'request_id': request_id,
                'applicant_id': applicant_id,
                'status': 'pending'
            }).execute()
        except Exception as e:
            raise Exception(f"Failed to express interest: {e}")
    
    async def has_applied_to_request(self, request_id: str, user_id: str) -> bool:
        """Check if user has applied to a request."""
        try:
            response = supabase.table('interests').select('id').eq('request_id', request_id).eq('applicant_id', user_id).execute()
            return len(response.data) > 0
        except Exception:
            return False
    
    async def get_applicants(self, request_id: str) -> List[InterestModel]:
        """Get all applicants for a request."""
        try:
            response = supabase.table('interests').select('*, users(*)').eq('request_id', request_id).eq('status', 'pending').execute()
            return [InterestModel.from_dict(item) for item in response.data]
        except Exception as e:
            raise Exception(f"Failed to get applicants: {e}")
    
    async def update_interest_status(self, interest_id: str, status: str) -> None:
        """Update interest status by ID."""
        try:
            supabase.table('interests').update({'status': status}).eq('id', interest_id).execute()
        except Exception as e:
            raise Exception(f"Failed to update interest: {e}")
    
    async def update_interest_status_by_request(self, request_id: str, applicant_id: str, status: str) -> None:
        """Update status for a specific interest."""
        try:
            supabase.table('interests').update({'status': status}).eq('request_id', request_id).eq('applicant_id', applicant_id).execute()
        except Exception as e:
            raise Exception(f"Failed to update interest: {e}")
    
    async def reject_all_other_interests(self, request_id: str, exclude_applicant_id: str) -> None:
        """Reject all other applicants."""
        try:
            supabase.table('interests').update({'status': 'rejected'}).eq('request_id', request_id).neq('applicant_id', exclude_applicant_id).execute()
        except Exception as e:
            raise Exception(f"Failed to reject applicants: {e}")
    
    async def get_rejected_applicants(self, request_id: str) -> List[Dict[str, Any]]:
        """Get rejected applicants with FCM tokens."""
        try:
            response = supabase.table('interests').select('users(fcm_token)').eq('request_id', request_id).eq('status', 'rejected').execute()
            return response.data
        except Exception as e:
            return []
    
    # ============ CHAT UNLOCKS ============
    
    async def log_chat_unlock(self, request_id: str, requester_id: str, applicant_id: str) -> None:
        """Log when contact was revealed."""
        try:
            supabase.table('chat_unlocks').insert({
                'request_id': request_id,
                'requester_id': requester_id,
                'applicant_id': applicant_id
            }).execute()
        except Exception as e:
            print(f"Failed to log unlock: {e}")