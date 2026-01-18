# recurring_transaction_routes.py

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity  # Sizin kullandığınız JWT kütüphanesini import ettik
from services.recurring_transaction_service import RecurringTransactionService

# Blueprint adını ve URL ön ekini belirleyin
recurring_bp = Blueprint('recurring_bp', __name__, url_prefix='/recurring')
service = RecurringTransactionService()


# Not: get_jwt_identity() ile dönen değer, sizin JWT kurulumunuza göre 'user_id' olmalıdır.

@recurring_bp.route('', methods=['GET'])
@jwt_required()
def get_user_transactions():
    """Kullanıcının tüm tekrar eden işlemlerini listeler."""
    # JWT'den kullanıcı kimliğini al
    user_id = get_jwt_identity()

    try:
        transactions = service.get_user_transactions(user_id)
        # to_dict metodu zaten JSON'a dönüştürülmüş listeyi döndürüyor.
        return jsonify(transactions), 200
    except Exception as e:
        # Hata durumunda loglama yapmak iyi bir uygulamadır
        print(f"Hata: {e}")
        return jsonify({"message": "Tekrarlayan işlemler alınırken bir hata oluştu."}), 500


@recurring_bp.route('', methods=['POST'])
@jwt_required()
def create_transaction():
    """Yeni bir tekrar eden işlem kaydı oluşturur."""
    user_id = get_jwt_identity()
    data = request.get_json()

    # Gerekli alanların kontrolü
    required_fields = ('amount', 'category_id', 'type', 'start_date', 'frequency')
    if not all(k in data for k in required_fields):
        return jsonify({"message": f"Eksik alanlar: {', '.join(required_fields)}."}), 400

    try:
        # Service katmanına 'user_id'yi gönderiyoruz
        transaction = service.create_transaction(user_id, data)
        return jsonify(transaction), 201
    except Exception as e:
        print(f"Hata: {e}")
        return jsonify({"message": "İşlem oluşturulurken hata oluştu.", "error": str(e)}), 400


@recurring_bp.route('/<string:transaction_id>', methods=['GET'])
@jwt_required()
def get_transaction(transaction_id):
    """Belirli bir işlemi ID ile getirir."""
    user_id = get_jwt_identity()

    transaction = service.get_transaction(transaction_id)

    # İşlemin varlığını ve o kullanıcıya ait olup olmadığını kontrol et
    if not transaction or transaction.user_id != user_id:
        return jsonify({"message": "İşlem bulunamadı veya yetkiniz yok."}), 404

    return jsonify(transaction.to_dict()), 200


@recurring_bp.route('/<string:transaction_id>', methods=['PUT', 'PATCH'])
@jwt_required()
def update_transaction(transaction_id):
    """Mevcut bir işlemi günceller."""
    user_id = get_jwt_identity()
    data = request.get_json()

    transaction_to_update = service.get_transaction(transaction_id)

    if not transaction_to_update or transaction_to_update.user_id != user_id:
        return jsonify({"message": "İşlem bulunamadı veya yetkiniz yok."}), 404

    try:
        # Service katmanı, update'i transaction_id üzerinden yapar
        updated_transaction = service.update_transaction(transaction_id, data)
        return jsonify(updated_transaction), 200
    except Exception as e:
        print(f"Hata: {e}")
        return jsonify({"message": "İşlem güncellenirken hata oluştu.", "error": str(e)}), 400


@recurring_bp.route('/<string:transaction_id>', methods=['DELETE'])
@jwt_required()
def delete_transaction(transaction_id):
    """Belirtilen işlemi siler."""
    user_id = get_jwt_identity()

    transaction_to_delete = service.get_transaction(transaction_id)

    if not transaction_to_delete or transaction_to_delete.user_id != user_id:
        return jsonify({"message": "İşlem bulunamadı veya yetkiniz yok."}), 404

    service.delete_transaction(transaction_id)
    # HTTP 204 No Content, başarılı silme işlemi için yaygın bir yanıttır.
    return jsonify({"message": "İşlem başarıyla silindi."}), 204