from werkzeug.security import generate_password_hash, check_password_hash
from flask_jwt_extended import create_access_token, create_refresh_token
from datetime import timedelta
from repositories.user_repository import UserRepository
from database.db import db

class AuthService:

    def register_user(self, data):
        password = data.get("password")
        if not password:
            raise ValueError("Password is required.")

        email = data.get('email')
        if UserRepository.get_by_email(email):
            return {"error": "Email already exists"}, 409

        hashed_password = generate_password_hash(data['password'])
        user_data = {
            'name': data.get('name'),
            'email': email,
            'password': hashed_password
        }
        user = UserRepository.create(user_data)
        return {"message": "User registered successfully", "user": user.serialize()}, 201

    def login_user(self, data):
        email = data.get('email')
        password = data.get('password')
        user = UserRepository.get_by_email(email)
        if not user or not check_password_hash(user.password, password):
            return {"error": "Invalid credentials"}, 401

        access_token = create_access_token(identity=user.id, expires_delta=timedelta(minutes=15))
        refresh_token = create_refresh_token(identity=user.id)
        return {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "user": user.serialize()
        }, 200
