# routes/transaction_route.py (ANA BACKEND'İNİZ)

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from services.transaction_service import TransactionService
from services.rbac_service import require_role
import requests  # Diğer servise istek atmak için
import json
from datetime import datetime

from services.category_service import CategoryService

transaction_bp = Blueprint('transaction_bp', __name__, url_prefix='/users/<user_id>/transactions')
transactionService = TransactionService()

ANOMALY_SERVICE_URL = "http://127.0.0.1:5002/api/anomaly/check-transaction"


@transaction_bp.route('', methods=['GET'])
@jwt_required()
def get_transactions(user_id):
    current_user_id = get_jwt_identity()
    if current_user_id != user_id:
        from models.user_model import User
        current_user = User.query.get(current_user_id)
        if not (current_user and current_user.role == 'ADMIN'):
            return {"error": "Insufficient permissions"}, 403

    transactions = transactionService.get_transactions_by_user(user_id)
    return jsonify([t.serialize() for t in transactions])


@transaction_bp.route('', methods=['POST'])
@jwt_required()
def create_transaction(user_id):
    current_user_id = get_jwt_identity()
    auth_header = request.headers.get('Authorization')

    if current_user_id != user_id:
        from models.user_model import User
        current_user = User.query.get(current_user_id)
        if not (current_user and current_user.role == 'ADMIN'):
            return {"error": "Insufficient permissions"}, 403

    try:
        data = request.get_json()
        print(f"[DEBUG] Received data: {data}")
        if not data:
            return {"error": "No data provided"}, 400

        transaction = transactionService.add_transaction_for_user(user_id, data)

        anomaly_response_json = {"is_anomaly": None, "message": "Anomali kontrolü yapılamadı."}

        try:
            history_transactions = transactionService.get_transactions_by_user(user_id)

            # -------- DÜZELTİLEN SATIRLAR BURADA --------
            categoryService = CategoryService()
            category_objects = categoryService.get_all_categories()

            # frontend category_id olarak isim gönderiyor → map name:name
            all_categories_map = {cat.name: cat.name for cat in category_objects}
            # --------------------------------------------

            history_list = []
            for t in history_transactions:
                history_list.append({
                    "date": t.date.isoformat(),
                    "amount": t.amount,
                    "type": t.type.name,
                    "category": all_categories_map.get(t.category_id, 'Other')
                })

            new_transaction_data = {
                "date": data.get('date', datetime.now().isoformat()),
                "amount": data.get('amount'),
                "category": all_categories_map.get(data.get('category_id'), 'Other'),
                "type": data.get('type')
            }

            anomaly_payload = {
                "user_history": history_list,
                "new_transaction": new_transaction_data
            }

            print("[DEBUG] Anomali servisine (Port 5002) gönderiliyor...")

            response = requests.post(
                ANOMALY_SERVICE_URL,
                headers={
                    "Content-Type": "application/json",
                    "Authorization": auth_header
                },
                json=anomaly_payload,
                timeout=10
            )

            if response.status_code == 200:
                anomaly_response_json = response.json()
                print(f"[DEBUG] Anomali sonucu: {anomaly_response_json.get('message')}")
            else:
                print(f"Anomali Servisi Hatası: {response.status_code} - {response.text}")
                anomaly_response_json = {"is_anomaly": None, "message": "Anomali servisi yanıt vermiyor."}

        except requests.exceptions.RequestException as e:
            print(f"Anomali Servisi Bağlantı Hatası: {e}")
            anomaly_response_json = {"is_anomaly": None, "message": "Anomali servisine bağlanılamadı."}

        final_response = transaction.serialize()
        final_response['anomaly_check'] = anomaly_response_json

        return jsonify(final_response), 201

    except ValueError as e:
        print(f"[ERROR] {str(e)}")
        return {"error": str(e)}, 400
    except Exception as e:
        print(f"[ERROR] Unexpected: {str(e)}")
        return {"error": "Internal server error"}, 500


@transaction_bp.route('/<transaction_id>', methods=['PUT'])
@jwt_required()
def update_transaction(user_id, transaction_id):
    current_user_id = get_jwt_identity()
    if current_user_id != user_id:
        from models.user_model import User
        current_user = User.query.get(current_user_id)
        if not (current_user and current_user.role == 'ADMIN'):
            return {"error": "Insufficient permissions"}, 403

    data = request.get_json()
    transaction = transactionService.update_transaction_for_user(user_id, transaction_id, data)
    if not transaction:
        return {"error": "Transaction not found for this user"}, 404
    return jsonify(transaction.serialize())


@transaction_bp.route('/<transaction_id>', methods=['DELETE'])
@jwt_required()
def delete_transaction(user_id, transaction_id):
    current_user_id = get_jwt_identity()
    if current_user_id != user_id:
        from models.user_model import User
        current_user = User.query.get(current_user_id)
        if not (current_user and current_user.role == 'ADMIN'):
            return {"error": "Insufficient permissions"}, 403

    success = transactionService.delete_transaction_for_user(user_id, transaction_id)
    if not success:
        return {"error": "Transaction not found for this user"}, 404
    return '', 204
