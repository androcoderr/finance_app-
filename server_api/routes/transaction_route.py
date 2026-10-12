from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from services.transaction_service import TransactionService
from routes.errors import server_error
from services.recurring_transaction_service import RecurringTransactionService

transaction_bp = Blueprint('transaction_bp', __name__, url_prefix='/users/<user_id>/transactions')
transactionService = TransactionService()


@transaction_bp.route('', methods=['GET'])
@jwt_required()
def get_transactions(user_id):
    current_user_id = get_jwt_identity()
    if current_user_id != user_id:  # herkes yalnızca kendi işlemlerine erişir
        return {"error": "Yetkiniz yok"}, 403

    # Vadesi gelen tekrarlayan işlemleri önce gerçek işleme dönüştür
    RecurringTransactionService.materialize_due(user_id)

    transactions = transactionService.get_transactions_by_user(user_id)
    return jsonify([t.serialize() for t in transactions])


@transaction_bp.route('', methods=['POST'])
@jwt_required()
def create_transaction(user_id):
    current_user_id = get_jwt_identity()

    if current_user_id != user_id:  # herkes yalnızca kendi işlemlerine erişir
        return {"error": "Yetkiniz yok"}, 403

    try:
        data = request.get_json(silent=True)
        if not isinstance(data, dict):
            return {"error": "Veri sağlanmadı"}, 400

        transaction = transactionService.add_transaction_for_user(user_id, data)

        return jsonify(transaction.serialize()), 201

    except ValueError as e:
        return {"error": str(e)}, 400
    except Exception as e:
        return server_error(e, 'create-transaction')


@transaction_bp.route('/<transaction_id>', methods=['PUT'])
@jwt_required()
def update_transaction(user_id, transaction_id):
    current_user_id = get_jwt_identity()
    if current_user_id != user_id:  # herkes yalnızca kendi işlemlerine erişir
        return {"error": "Yetkiniz yok"}, 403

    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        return {"error": "Veri sağlanmadı"}, 400
    try:
        transaction = transactionService.update_transaction_for_user(user_id, transaction_id, data)
    except ValueError as e:
        return {"error": str(e)}, 400
    if not transaction:
        return {"error": "Transaction not found for this user"}, 404
    return jsonify(transaction.serialize())


@transaction_bp.route('/<transaction_id>', methods=['DELETE'])
@jwt_required()
def delete_transaction(user_id, transaction_id):
    current_user_id = get_jwt_identity()
    if current_user_id != user_id:  # herkes yalnızca kendi işlemlerine erişir
        return {"error": "Yetkiniz yok"}, 403

    success = transactionService.delete_transaction_for_user(user_id, transaction_id)
    if not success:
        return {"error": "Transaction not found for this user"}, 404
    return '', 204
