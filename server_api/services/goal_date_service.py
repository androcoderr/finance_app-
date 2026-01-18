from repositories.goal_date_repository import GoalDateRepository
from repositories.goal_repository import GoalRepository
from datetime import datetime


class GoalDateService:

    def create_goal_date(self, goal_id, date_str, user_id):
        """Create a new goal date after validating that the goal belongs to the user"""
        from models.goal_model import Goal
        
        # Verify that the goal exists and belongs to the user
        goal = Goal.query.filter_by(id=goal_id, user_id=user_id).first()
        if not goal:
            raise ValueError("Goal not found or does not belong to user")
        
        return GoalDateRepository.create(goal_id, date_str)

    def get_goal_dates(self, goal_id, user_id):
        """Get all dates for a specific goal after validating user ownership"""
        from models.goal_model import Goal
        
        # Verify that the goal exists and belongs to the user
        goal = Goal.query.filter_by(id=goal_id, user_id=user_id).first()
        if not goal:
            raise ValueError("Goal not found or does not belong to user")
        
        return GoalDateRepository.get_by_goal_id(goal_id)

    def get_goal_date_by_id(self, goal_date_id, user_id):
        """Get a specific goal date by ID after validating user ownership"""
        goal_date = GoalDateRepository.get_by_id(goal_date_id)
        if not goal_date:
            return None
        
        # Verify that the associated goal belongs to the user
        from models.goal_model import Goal
        goal = Goal.query.filter_by(id=goal_date.goal_id, user_id=user_id).first()
        if not goal:
            raise ValueError("Goal date does not belong to user")
        
        return goal_date

    def update_goal_date(self, goal_date_id, date_str, user_id):
        """Update a goal date after validating user ownership"""
        goal_date = GoalDateRepository.get_by_id(goal_date_id)
        if not goal_date:
            raise ValueError("Goal date not found")
        
        # Verify that the associated goal belongs to the user
        from models.goal_model import Goal
        goal = Goal.query.filter_by(id=goal_date.goal_id, user_id=user_id).first()
        if not goal:
            raise ValueError("Goal date does not belong to user")
        
        return GoalDateRepository.update(goal_date_id, date_str)

    def delete_goal_date(self, goal_date_id, user_id):
        """Delete a goal date after validating user ownership"""
        goal_date = GoalDateRepository.get_by_id(goal_date_id)
        if not goal_date:
            return False
        
        # Verify that the associated goal belongs to the user
        from models.goal_model import Goal
        goal = Goal.query.filter_by(id=goal_date.goal_id, user_id=user_id).first()
        if not goal:
            raise ValueError("Goal date does not belong to user")
        
        return GoalDateRepository.delete(goal_date_id)