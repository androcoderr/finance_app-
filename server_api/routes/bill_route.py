from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from services.bill_service import BillService

# Blueprint'in URL prefix'i basitleştirildi. Artık /bills altında çalışacak.
bill_bp = Blueprint('bill_bp', __name__, url_prefix='/bills')
bill_service = BillService()


@bill_bp.route('', methods=['GET'])
@jwt_required()
def get_user_bills():
    """(GÜVENLİ) Token'dan alınan kullanıcının faturalarını getirir."""
    try:
        current_user_id = get_jwt_identity()
        bills = bill_service.get_bills_with_status(current_user_id)
        return jsonify(bills), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@bill_bp.route('', methods=['POST'])
@jwt_required()
def add_user_bill():
    """(GÜVENLİ) Token'dan alınan kullanıcıya yeni fatura ekler."""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        if not data:
            return jsonify({"error": "Veri sağlanmadı"}), 400

        new_bill = bill_service.add_bill(current_user_id, data)
        return jsonify(new_bill.serialize()), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@bill_bp.route('/<bill_id>', methods=['PUT'])
@jwt_required()
def update_user_bill(bill_id):
    """(GÜVENLİ) Token'dan alınan kullanıcının faturasını günceller."""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        updated_bill = bill_service.update_bill(current_user_id, bill_id, data)
        if not updated_bill:
            return jsonify({"error": "Fatura bulunamadı"}), 404
        return jsonify(updated_bill.serialize()), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@bill_bp.route('/<bill_id>', methods=['DELETE'])
@jwt_required()
def delete_user_bill(bill_id):
    """(GÜVENLİ) Token'dan alınan kullanıcının faturasını siler."""
    current_user_id = get_jwt_identity()
    success = bill_service.delete_bill(current_user_id, bill_id)
    if not success:
        return jsonify({"error": "Fatura bulunamadı"}), 404
    return '', 204


@bill_bp.route('/<bill_id>/pay', methods=['POST'])
@jwt_required()
def pay_bill(bill_id):
    """(GÜVENLİ) Token'dan alınan kullanıcının faturasını öder."""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        payment_record = bill_service.mark_bill_as_paid(current_user_id, bill_id, data)
        return jsonify(payment_record.serialize()), 201
    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        return jsonify({"error": "Bir hata oluştu: " + str(e)}), 500

