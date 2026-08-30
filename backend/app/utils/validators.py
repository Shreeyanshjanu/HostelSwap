# app/utils/validators.py

from typing import Dict, Any, List

class Validators:
    
    # Allowed hostel lists
    BOYS_HOSTELS = ["BH-1", "BH-2", "BH-3"]
    GIRLS_HOSTELS = ["GH-1", "GH-2", "GH-3"]
    ALL_HOSTELS = BOYS_HOSTELS + GIRLS_HOSTELS
    SEATER_TYPES = [2, 3, 4, 5]
    
    @classmethod
    def validate_swap_data(cls, data: Dict[str, Any]) -> tuple:
        """Validate parsed swap request data."""
        
        # Check current hostel
        if data.get('current_hostel') not in cls.ALL_HOSTELS:
            return False, f"Invalid current hostel. Must be one of: {', '.join(cls.ALL_HOSTELS)}"
        
        # Check desired hostel
        if data.get('desired_hostel') not in cls.ALL_HOSTELS:
            return False, f"Invalid desired hostel. Must be one of: {', '.join(cls.ALL_HOSTELS)}"
        
        # Check current seater
        if data.get('current_seater') not in cls.SEATER_TYPES:
            return False, f"Invalid seater type. Must be: 2, 3, 4, or 5"
        
        # Check desired seater (if provided)
        if data.get('desired_seater') is not None:
            if data['desired_seater'] not in cls.SEATER_TYPES:
                return False, f"Invalid desired seater. Must be: 2, 3, 4, or 5"
        
        # Check AC types
        if data.get('current_ac') not in [True, False]:
            return False, "Invalid AC type. Must be true or false"
        
        if data.get('desired_ac') is not None:
            if data['desired_ac'] not in [True, False]:
                return False, "Invalid desired AC type. Must be true, false, or null"
        
        return True, "Valid"
    
    @classmethod
    def is_valid_college_id(cls, college_id: str) -> bool:
        """Validate college ID format."""
        import re
        # Update this regex based on your college format
        # Example: 2024CS101 (Year + Branch + Roll)
        pattern = r'^[0-9]{4}[A-Z]{2}[0-9]{3}$'
        return bool(re.match(pattern, college_id))
    
    @classmethod
    def is_valid_phone(cls, phone: str) -> bool:
        """Validate phone number."""
        import re
        pattern = r'^[0-9]{10}$'
        return bool(re.match(pattern, phone))