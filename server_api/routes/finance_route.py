# routes/finance_route.py

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity

finance_bp = Blueprint('finance_bp', __name__, url_prefix='/finance')


@finance_bp.route('/<goal_id>', methods=['POST'])
@jwt_required()
def analyze_goal_onnx(goal_id):
    """
    ONNX-based financial analysis endpoint (legacy).
    
    This is the original endpoint for ONNX model inference.
    """
    current_user_id = get_jwt_identity()

    from models.goal_model import Goal
    goal = Goal.query.filter_by(id=goal_id, user_id=current_user_id).first()
    if not goal:
        return jsonify({"error": "Goal not found or does not belong to user"}), 404

    import onnxruntime as ort
    import numpy as np
    import os

    model_path = os.path.join('models', 'model.onnx')
    if not os.path.exists(model_path):
        return jsonify({"error": "Model file not found"}), 500

    session = ort.InferenceSession(model_path)
    input_name = session.get_inputs()[0].name

    target = float(goal.target_amount)
    current = float(goal.current_amount)
    remaining = target - current

    from models.goal_date import GoalDate
    goal_dates = GoalDate.query.filter_by(goal_id=goal_id).all()
    
    if not goal_dates:
        return jsonify({"error": "No goal dates found for this goal"}), 404

    from datetime import datetime
    today = datetime.now()
    future_dates = [gd for gd in goal_dates if datetime.fromisoformat(str(gd.date)) > today]
    
    if not future_dates:
        return jsonify({"error": "No future goal dates available"}), 404

    target_date = min(future_dates, key=lambda gd: datetime.fromisoformat(str(gd.date)))
    delta_days = (datetime.fromisoformat(str(target_date.date)) - today).days
    
    if delta_days <= 0:
        return jsonify({"error": "Goal date is in the past or today"}), 400

    monthly_needed = remaining / max((delta_days / 30), 1)

    input_data = np.array([[
        float(target),
        float(current),
        float(remaining),
        float(delta_days)
    ]], dtype=np.float32)

    outputs = session.run(None, {input_name: input_data})
    probability = float(outputs[0][0][0])
    risk = float(outputs[1][0][0])

    return jsonify({
        "probability": round(probability * 100, 2),
        "risk": round(risk * 100, 2),
        "monthly_needed": round(monthly_needed, 2),
        "days_remaining": delta_days
    })


@finance_bp.route('/budget_analysis', methods=['POST'])
@jwt_required()
def budget_analysis():
    """
    PyTorch-based budget analysis endpoint for specific goals.
    
    Analyzes user's transaction history and provides personalized budget recommendations
    for a specific goal with Turkish-language explanations.
    
    Request Body:
    {
        "goal_id": "uuid-string",  # Required
        "goal_date": "2024-12-31"   # Optional, uses latest goal_date if not provided
    }
    
    Returns goal-specific analysis with Turkish description.
    """
    current_user_id = get_jwt_identity()
    
    # Get request body
    data = request.get_json()
    if not data:
        return jsonify({"error": "Request body required"}), 400
    
    goal_id = data.get('goal_id')
    if not goal_id:
        return jsonify({"error": "goal_id is required"}), 400
    
    goal_date = data.get('goal_date')  # Optional
    
    # Verify goal belongs to user
    from models.goal_model import Goal
    goal = Goal.query.filter_by(id=goal_id, user_id=current_user_id).first()
    if not goal:
        return jsonify({"error": "Goal not found or does not belong to user"}), 404
    
    # Import here to avoid circular dependencies
    from services.ai_anomaly_service import AIService
    from models.model_lock_user_data import ModelLockUserData
    
    # Create user data object with goal information
    user_data = ModelLockUserData(current_user_id, goal_id=goal_id, goal_date=goal_date)
    
    # Get AI service instance
    ai_service = AIService()
    
    # Queue the request for background processing
    ai_service.queue_request(user_data)
    
    print(f"\n>>> Budget analysis request received for user: {current_user_id}, goal: {goal_id}")
    
    return jsonify({
        "status": "accepted",
        "message": "Budget analysis queued for processing. Check server logs for results.",
        "user_id": current_user_id,
        "goal_id": goal_id
    }), 202


@finance_bp.route('/budget_analysis/<goal_id>/result', methods=['GET'])
@jwt_required()
def get_budget_analysis_result(goal_id):
    """
    Get budget analysis result for a specific goal.
    
    Returns cached result if available, otherwise 404.
    
    URL: GET /finance/budget_analysis/<goal_id>/result
    """
    current_user_id = get_jwt_identity()
    
    # Verify goal belongs to user
    from models.goal_model import Goal
    goal = Goal.query.filter_by(id=goal_id, user_id=current_user_id).first()
    if not goal:
        return jsonify({"error": "Goal not found or does not belong to user"}), 404
    
    # Get result from cache
    from services.ai_anomaly_service import AIService
    ai_service = AIService()
    result = ai_service.get_result(goal_id)
    
    if result:
        return jsonify(result), 200
    else:
        return jsonify({
            "error": "No analysis result found for this goal",
            "message": "Budget analysis may still be processing or hasn't been requested yet. Please try again in a few seconds."
        }), 404