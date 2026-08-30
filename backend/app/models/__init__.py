# backend/app/models/__init__.py

from .user_model import UserModel
from .request_model import RequestModel
from .interest_model import InterestModel

__all__ = [
    'UserModel',
    'RequestModel',
    'InterestModel'
]
