from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from services.goal_service import GoalService
from services.goal_date_service import GoalDateService

goal_bp = Blueprint('goal_bp', __name__, url_prefix='/goals')
goalService = GoalService()
goalDateService = GoalDateService()

@goal_bp.route('', methods=['POST'])
@jwt_required()
def create_goal():
    user_id = get_jwt_identity()
    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        return {"error": "Veri sağlanmadı"}, 400
    try:
        goal = goalService.create_goal(user_id, data)
    except ValueError as e:
        return {"error": str(e)}, 400
    return jsonify(goal_id=goal.id), 201

@goal_bp.route('', methods=['GET'])
@jwt_required()
def get_goals():
    user_id = get_jwt_identity()
    from models.goal_model import Goal
    # Get goals with their associated dates
    goals = Goal.query.filter_by(user_id=user_id).all()
    
    result = []
    for g in goals:
        goal_data = {
            'id': g.id,
            'name': g.name,
            'target_amount': g.target_amount,
            'current_amount': g.current_amount
        }
        
        # Get associated goal dates
        try:
            goal_dates = goalDateService.get_goal_dates(g.id, user_id)
            goal_data['goal_dates'] = [gd.serialize() for gd in goal_dates]
        except ValueError:
            # If there are issues accessing goal dates, continue without them
            goal_data['goal_dates'] = []
        
        result.append(goal_data)
    
    return jsonify(result), 200

@goal_bp.route('/<goal_id>', methods=['PUT'])
@jwt_required()
def update_goal(goal_id):
    user_id = get_jwt_identity()
    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        return {"error": "Veri sağlanmadı"}, 400
    try:
        goal = goalService.update_goal(user_id, goal_id, data)
    except ValueError as e:
        return {"error": str(e)}, 400
    if not goal:
        return {"error": "Goal not found"}, 404
    return jsonify(message="Goal updated successfully"), 200

@goal_bp.route('/<goal_id>', methods=['DELETE'])
@jwt_required()
def delete_goal(goal_id):
    user_id = get_jwt_identity()
    success = goalService.delete_goal(user_id, goal_id)
    if not success:
        return {"error": "Goal not found"}, 404
    return jsonify(message="Goal deleted successfully"), 200
