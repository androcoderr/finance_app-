from flask import Blueprint, jsonify, request
from services.user_service import UserService
from flask_jwt_extended import jwt_required, get_jwt_identity
from services.rbac_service import require_role

user_bp = Blueprint('user_bp', __name__, url_prefix='/users')
userService = UserService()

# =============================================================================
# STATİK ROTALAR (Önce tanımlanmalı)
# =============================================================================

@user_bp.route('/profile', methods=['PUT'])
@jwt_required()
def update_profile():
    """Giriş yapmış kullanıcının profil bilgilerini (ad, e-posta) günceller."""
    current_user_id = get_jwt_identity()
    data = request.get_json()
    
    try:
        updated_user = userService.update_user_profile(current_user_id, data)
        return jsonify({
            "message": "Profil başarıyla güncellendi",
            "user": updated_user.serialize()
        }), 200
    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        return jsonify({"error": "Sunucu hatası: " + str(e)}), 500

@user_bp.route('/roles', methods=['GET'])
@jwt_required()
@require_role('ADMIN')
def get_all_users_with_roles():
    """Admin kullanıcının tüm kullanıcı ve rollerini görmesine izin verir."""
    try:
        users = userService.get_all_users()
        return jsonify([user.serialize() for user in users])
    except Exception as e:
        return {"error": str(e)}, 500

@user_bp.route('', methods=['GET'])
def get_users():
    """Tüm kullanıcıları listeler (Genellikle admin panelleri için kullanılır)."""
    users = userService.get_all_users()
    return jsonify([user.serialize() for user in users])

@user_bp.route('', methods=['POST'])
def create_user():
    """Yeni kullanıcı oluşturur (Admin veya kayıt dışı kullanım)."""
    data = request.get_json()
    try:
        new_user = userService.create_user(data)
        return jsonify(new_user.serialize()), 201
    except ValueError as e:
        return jsonify({"error": str(e)}), 400

# =============================================================================
# DİNAMİK ROTALAR (En sona tanımlanmalı)
# =============================================================================

@user_bp.route('/<user_id>', methods=['GET'])
def get_user(user_id):
    """Belirli bir kullanıcıyı ID ile getirir."""
    user = userService.get_user_by_id(user_id)
    if not user:
        return {"error": "User not found"}, 404
    return jsonify(user.serialize())

@user_bp.route('/<user_id>/role', methods=['PUT'])
@jwt_required()
@require_role('ADMIN')
def update_user_role(user_id):
    """Admin kullanıcının başka bir kullanıcının rolünü güncellemesine izin verir."""
    try:
        data = request.get_json()
        new_role = data.get('role')

        if not new_role or new_role not in ['USER', 'ADMIN']:
            return {"error": "Valid role (USER or ADMIN) is required"}, 400

        updated_user = userService.update_user_role(user_id, new_role)
        if not updated_user:
            return {"error": "User not found"}, 404

        return jsonify(updated_user.serialize()), 200
    except Exception as e:
        return {"error": str(e)}, 500
