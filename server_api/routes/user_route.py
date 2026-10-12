from flask import Blueprint, jsonify, request
from services.user_service import UserService
from flask_jwt_extended import jwt_required, get_jwt_identity
from routes.errors import server_error

user_bp = Blueprint('user_bp', __name__, url_prefix='/users')
userService = UserService()


@user_bp.route('/profile', methods=['PUT'])
@jwt_required()
def update_profile():
    """Giriş yapmış kullanıcının profil bilgilerini (ad, e-posta) günceller."""
    current_user_id = get_jwt_identity()
    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        return jsonify({"error": "Veri sağlanmadı"}), 400

    try:
        updated_user = userService.update_user_profile(current_user_id, data)
        return jsonify({
            "message": "Profil başarıyla güncellendi",
            "user": updated_user.serialize()
        }), 200
    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        return server_error(e, 'update-profile')

@user_bp.route('/profile', methods=['DELETE'])
@jwt_required()
def delete_account():
    """Giriş yapmış kullanıcının hesabını ve tüm verilerini kalıcı olarak siler (Google Play zorunluluğu)."""
    from database.db import db
    from models.user_model import User
    from models.bill_model import Bill

    current_user_id = get_jwt_identity()
    user = User.query.get(current_user_id)
    if not user:
        return jsonify({"error": "Kullanıcı bulunamadı"}), 404

    try:
        # User üzerinde cascade tanımlı olmayan tablolar
        for bill in Bill.query.filter_by(user_id=current_user_id).all():
            db.session.delete(bill)  # ödemeleri cascade ile silinir
        # İşlemler, hedefler, bütçeler, tekrarlayan işlemler, 2FA oturumları cascade ile silinir
        db.session.delete(user)
        db.session.commit()
        return jsonify({"message": "Hesap ve tüm veriler silindi"}), 200
    except Exception as e:
        db.session.rollback()
        return server_error(e, 'delete-account')
