from functools import wraps
from flask import jsonify
from flask_jwt_extended import get_jwt_identity
from models.user_model import User
from database.db import db


def require_role(required_role):
    """
    Decorator to check if user has a specific role
    Usage: @require_role('ADMIN') or @require_role(['ADMIN', 'MODERATOR'])
    """
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            current_user_id = get_jwt_identity()
            
            # Get user from database
            user = User.query.get(current_user_id)
            if not user:
                return jsonify({'error': 'User not found'}), 404
            
            # Check if required_role is a string or list
            if isinstance(required_role, str):
                required_roles = [required_role]
            else:
                required_roles = required_role
            
            # Check if user has the required role
            if user.role not in required_roles:
                return jsonify({'error': 'Insufficient permissions'}), 403
            
            return fn(*args, **kwargs)
        return wrapper
    return decorator


def require_any_role(*required_roles):
    """
    Decorator to check if user has any of the specified roles
    Usage: @require_any_role('ADMIN', 'MODERATOR') or @require_any_role(['ADMIN', 'MODERATOR'])
    """
    # Flatten required_roles in case it's passed as a list
    all_required_roles = []
    for role in required_roles:
        if isinstance(role, list):
            all_required_roles.extend(role)
        else:
            all_required_roles.append(role)
    
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            current_user_id = get_jwt_identity()
            
            # Get user from database
            user = User.query.get(current_user_id)
            if not user:
                return jsonify({'error': 'User not found'}), 404
            
            # Check if user has any of the required roles
            if user.role not in all_required_roles:
                return jsonify({'error': 'Insufficient permissions'}), 403
            
            return fn(*args, **kwargs)
        return wrapper
    return decorator