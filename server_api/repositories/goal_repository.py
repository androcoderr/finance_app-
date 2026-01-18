from models.goal_model import Goal
from database.db import db

class GoalRepository:

    @staticmethod
    def create(goal_data):
        goal = Goal(**goal_data)
        db.session.add(goal)
        db.session.commit()
        return goal

    @staticmethod
    def get_by_user(user_id):
        return Goal.query.filter_by(user_id=user_id).all()

    @staticmethod
    def get_by_id_and_user(goal_id, user_id):
        return Goal.query.filter_by(id=goal_id, user_id=user_id).first()

    @staticmethod
    def update(goal_id, user_id, update_data):
        goal = GoalRepository.get_by_id_and_user(goal_id, user_id)
        if not goal:
            return None
        for key, value in update_data.items():
            if hasattr(goal, key):
                setattr(goal, key, value)
        db.session.commit()
        return goal

    @staticmethod
    def delete(goal_id, user_id):
        goal = GoalRepository.get_by_id_and_user(goal_id, user_id)
        if not goal:
            return False
        db.session.delete(goal)
        db.session.commit()
        return True
