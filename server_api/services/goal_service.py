from repositories.goal_repository import GoalRepository
from services.goal_date_service import GoalDateService
from datetime import datetime


class GoalService:
    
    def __init__(self):
        self.goal_date_service = GoalDateService()

    def create_goal(self, user_id, data):
        # Extract goal_date if provided
        goal_date_str = data.pop('goal_date', None)
        
        # Create the goal
        data['user_id'] = user_id
        goal = GoalRepository.create(data)
        
        # If a goal date was provided, create the associated goal date
        if goal_date_str:
            try:
                self.goal_date_service.create_goal_date(goal.id, goal_date_str, user_id)
            except ValueError as e:
                # If goal date creation fails, we might want to rollback the goal creation
                # For now, let's just log the error
                print(f"Error creating goal date: {e}")
        
        return goal

    def get_goals_for_user(self, user_id):
        return GoalRepository.get_by_user(user_id)

    def get_goal_by_id(self, user_id, goal_id):
        from models.goal_model import Goal
        # Get the goal with its associated dates
        goal = Goal.query.filter_by(id=goal_id, user_id=user_id).first()
        return goal

    def update_goal(self, user_id, goal_id, data):
        # Extract goal_date if provided
        goal_date_str = data.pop('goal_date', None)
        
        # Update the goal
        result = GoalRepository.update(goal_id, user_id, data)
        
        # If a goal date was provided, create or update the associated goal date
        if goal_date_str:
            try:
                # Try to find existing goal date for this goal
                existing_goal_dates = self.goal_date_service.get_goal_dates(goal_id, user_id)
                if existing_goal_dates:
                    # Update the first existing goal date
                    # For simplicity, we're updating the first one if multiple exist
                    if existing_goal_dates:
                        # Since our repository doesn't have a direct update method for date by goal_id,
                        # we need to create a new one or update through the specific ID
                        # Let's create a new one and remove old ones
                        goal_date_id = existing_goal_dates[0].id
                        self.goal_date_service.update_goal_date(goal_date_id, goal_date_str, user_id)
                else:
                    # Create a new goal date
                    self.goal_date_service.create_goal_date(goal_id, goal_date_str, user_id)
            except ValueError as e:
                print(f"Error updating goal date: {e}")
        
        return result

    def delete_goal(self, user_id, goal_id):
        return GoalRepository.delete(goal_id, user_id)
