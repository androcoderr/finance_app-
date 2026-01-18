from database.db import db
import uuid
from datetime import datetime
from sqlalchemy import Date

class Goal(db.Model):
    __tablename__ = 'goals'

    id = db.Column(db.String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String, db.ForeignKey('users.id'), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    target_amount = db.Column(db.Float, nullable=False)
    current_amount = db.Column(db.Float, default=0.0)
    
    # Relationship to goal dates
    goal_dates = db.relationship('GoalDate', backref='goal', lazy=True, cascade="all, delete-orphan")