from database.db import db
import uuid
from datetime import datetime
from sqlalchemy import Date

class GoalDate(db.Model):
    __tablename__ = 'goaldates'

    id = db.Column(db.String, primary_key=True, default=lambda: str(uuid.uuid4()))
    goal_id = db.Column(db.String, db.ForeignKey('goals.id'), nullable=False)
    date = db.Column(db.Date, nullable=False)
    
    def serialize(self):
        return {
            'id': self.id,
            'goal_id': self.goal_id,
            'date': self.date.isoformat() if self.date else None
        }