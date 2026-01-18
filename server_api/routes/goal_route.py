from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from services.goal_service import GoalService
from services.goal_date_service import GoalDateService
from datetime import datetime

goal_bp = Blueprint('goal_bp', __name__, url_prefix='/goals')
goalService = GoalService()
goalDateService = GoalDateService()

@goal_bp.route('', methods=['POST'])
@jwt_required()
def create_goal():
    user_id = get_jwt_identity()
    data = request.get_json()
    goal = goalService.create_goal(user_id, data)
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
    data = request.get_json()
    goal = goalService.update_goal(user_id, goal_id, data)
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

# Additional route for managing goal dates
@goal_bp.route('/<goal_id>/dates', methods=['GET'])
@jwt_required()
def get_goal_dates(goal_id):
    """Get all dates associated with a specific goal"""
    user_id = get_jwt_identity()
    try:
        goal_dates = goalDateService.get_goal_dates(goal_id, user_id)
        return jsonify([gd.serialize() for gd in goal_dates]), 200
    except ValueError as e:
        return jsonify({"error": str(e)}), 403

@goal_bp.route('/<goal_id>/dates', methods=['POST'])
@jwt_required()
def add_goal_date(goal_id):
    """Add a date to a specific goal"""
    user_id = get_jwt_identity()
    data = request.get_json()
    date_str = data.get('date')
    
    if not date_str:
        return jsonify({"error": "Date is required"}), 400
    
    try:
        goal_date = goalDateService.create_goal_date(goal_id, date_str, user_id)
        return jsonify(goal_date.serialize()), 201
    except ValueError as e:
        return jsonify({"error": str(e)}), 400

@goal_bp.route('/dates/<goal_date_id>', methods=['PUT'])
@jwt_required()
def update_goal_date(goal_date_id):
    """Update a specific goal date"""
    user_id = get_jwt_identity()
    data = request.get_json()
    date_str = data.get('date')
    
    if not date_str:
        return jsonify({"error": "Date is required"}), 400
    
    try:
        goal_date = goalDateService.update_goal_date(goal_date_id, date_str, user_id)
        if not goal_date:
            return jsonify({"error": "Goal date not found"}), 404
        return jsonify(goal_date.serialize()), 200
    except ValueError as e:
        return jsonify({"error": str(e)}), 400

@goal_bp.route('/dates/<goal_date_id>', methods=['DELETE'])
@jwt_required()
def delete_goal_date(goal_date_id):
    """Delete a specific goal date"""
    user_id = get_jwt_identity()
    try:
        success = goalDateService.delete_goal_date(goal_date_id, user_id)
        if not success:
            return jsonify({"error": "Goal date not found"}), 404
        return jsonify({"message": "Goal date deleted successfully"}), 200
    except ValueError as e:
        return jsonify({"error": str(e)}), 400
