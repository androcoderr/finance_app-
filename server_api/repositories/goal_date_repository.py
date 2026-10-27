from models.goal_date import GoalDate
from models.goal_model import Goal
from database.db import db
from datetime import datetime
from sqlalchemy import func
import uuid


class GoalDateRepository:

    @staticmethod
    def create(goal_id, date_str):
        """Create a new goal date record"""
        from datetime import datetime
        
        try:
            # Parse the date string in format "10-05-2015" (day-month-year)
            date_obj = datetime.strptime(date_str, "%d-%m-%Y").date()
        except (ValueError, TypeError):
            # Try alternate format "2015-05-10" (ISO format)
            try:
                date_obj = datetime.strptime(date_str, "%Y-%m-%d").date()
            except (ValueError, TypeError):
                raise ValueError("Tarih geçersiz. GG-AA-YYYY veya YYYY-AA-GG biçiminde girin.")
        
        goal_date = GoalDate(
            goal_id=goal_id,
            date=date_obj
        )
        db.session.add(goal_date)
        db.session.commit()
        return goal_date

    @staticmethod
    def get_by_goal_id(goal_id):
        """Get all dates associated with a specific goal"""
        return GoalDate.query.filter_by(goal_id=goal_id).all()

    @staticmethod
    def get_by_id(goal_date_id):
        """Get a specific goal date by ID"""
        return GoalDate.query.get(goal_date_id)

    @staticmethod
    def update(goal_date_id, date_str):
        """Update a goal date"""
        from datetime import datetime
        
        goal_date = GoalDate.query.get(goal_date_id)
        if not goal_date:
            return None
        
        try:
            # Parse the date string in format "10-05-2015" (day-month-year)
            date_obj = datetime.strptime(date_str, "%d-%m-%Y").date()
        except (ValueError, TypeError):
            # Try alternate format "2015-05-10" (ISO format)
            try:
                date_obj = datetime.strptime(date_str, "%Y-%m-%d").date()
            except (ValueError, TypeError):
                raise ValueError("Tarih geçersiz. GG-AA-YYYY veya YYYY-AA-GG biçiminde girin.")
                
        goal_date.date = date_obj
        db.session.commit()
        return goal_date
