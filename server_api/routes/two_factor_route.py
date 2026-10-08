from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity, create_access_token
from database.db import db
from models.user_model import User
from models.two_factor_session_model import TwoFactorSession
from services.firebase_service import FirebaseService
from datetime import datetime
from routes.errors import server_error

two_factor_bp = Blueprint('two_factor', __name__, url_prefix='/api/2fa')


@two_factor_bp.route('/enable', methods=['POST'])
@jwt_required()
def enable_2fa():
    """2FA'yı aktifleştir"""
    if not current_app.config['TWO_FACTOR_ENABLED']:
        return jsonify({'error': 'İki aşamalı doğrulama şu anda kullanılamıyor'}), 403
    try:
        user_id = get_jwt_identity()
        data = request.get_json()

        fcm_token = data.get('fcm_token')

        if not fcm_token:
            return jsonify({'error': 'FCM token gerekli'}), 400

        # Kullanıcıyı bul
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'Kullanıcı bulunamadı'}), 404

        # 2FA'yı aktifleştir
        user.two_factor_enabled = True
        user.fcm_token = fcm_token

        db.session.commit()

        return jsonify({
            'success': True,
            'message': 'İki aşamalı doğrulama başarıyla aktifleştirildi',
            'user': user.serialize()
        }), 200

    except Exception as e:
        db.session.rollback()
        return server_error(e, '2fa')


@two_factor_bp.route('/disable', methods=['POST'])
@jwt_required()
def disable_2fa():
    """2FA'yı devre dışı bırak"""
    try:
        user_id = get_jwt_identity()

        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'Kullanıcı bulunamadı'}), 404

        user.two_factor_enabled = False
        user.fcm_token = None

        db.session.commit()

        return jsonify({
            'success': True,
            'message': 'İki aşamalı doğrulama kapatıldı'
        }), 200

    except Exception as e:
        db.session.rollback()
        return server_error(e, '2fa')


@two_factor_bp.route('/update-token', methods=['POST'])
@jwt_required()
def update_fcm_token():
    """FCM token'ı güncelle"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()

        fcm_token = data.get('fcm_token')

        if not fcm_token:
            return jsonify({'error': 'FCM token gerekli'}), 400

        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'Kullanıcı bulunamadı'}), 404

        user.fcm_token = fcm_token
        db.session.commit()

        return jsonify({
            'success': True,
            'message': 'FCM token güncellendi'
        }), 200

    except Exception as e:
        db.session.rollback()
        return server_error(e, '2fa')


@two_factor_bp.route('/verify/<session_token>', methods=['POST'])
@jwt_required()
def verify_2fa(session_token):
    """
    2FA doğrulama - Kullanıcı bildirimdeki Onayla/Reddet butonuna bastığında.
    Yalnızca aynı hesapla oturum açmış (güvenilir) cihaz onaylayabilir.
    """
    try:
        data = request.get_json() or {}
        approved = data.get('approved', False) is True

        # Session'ı bul
        session = TwoFactorSession.query.filter_by(session_token=session_token).first()

        if not session or session.user_id != get_jwt_identity():
            return jsonify({'error': 'Session bulunamadı'}), 404

        # Süresi dolmuş mu kontrol et
        if session.is_expired():
            session.expire()
            db.session.commit()
            return jsonify({'error': 'Session süresi doldu'}), 400

        # Zaten yanıtlanmış mı?
        if session.status != 'pending':
            return jsonify({'error': f'Session zaten {session.status}'}), 400

        # Kullanıcıyı bul
        user = User.query.get(session.user_id)

        if approved:
            session.approve()
            db.session.commit()

            # Onay bildirimi gönder
            if user.fcm_token:
                FirebaseService.send_2fa_approved_notification(user.fcm_token, user.email)

            return jsonify({
                'success': True,
                'message': 'Giriş onaylandı',
                'status': 'approved'
            }), 200
        else:
            session.reject()
            db.session.commit()

            # Red bildirimi gönder
            if user.fcm_token:
                FirebaseService.send_2fa_rejected_notification(user.fcm_token, user.email)

            return jsonify({
                'success': True,
                'message': 'Giriş reddedildi',
                'status': 'rejected'
            }), 200

    except Exception as e:
        db.session.rollback()
        return server_error(e, '2fa')


@two_factor_bp.route('/check-status/<session_token>', methods=['GET'])
def check_2fa_status(session_token):
    """
    Session durumunu kontrol et - GÜNCELLENMİŞ VERSİYON
    Durum 'approved' ise access_token ve user bilgisini de döndürür.
    """
    try:
        session = TwoFactorSession.query.filter_by(session_token=session_token).first()

        if not session:
            return jsonify({'error': 'Session bulunamadı'}), 404

        if session.is_expired():
            if session.status == 'pending':
                session.expire()
                db.session.commit()
            return jsonify({'status': 'expired', 'is_expired': True}), 200

        # Onaylandıysa token'lar bir kez verilir ve oturum silinir
        if session.status == 'approved':
            from routes.auth_route import finish_approved_2fa_session
            return jsonify(finish_approved_2fa_session(session)), 200

        response_data = {
            'status': session.status,
            'is_expired': session.is_expired(),
            'expires_at': session.expires_at.isoformat(),
            'created_at': session.created_at.isoformat()
        }

        return jsonify(response_data), 200

    except Exception as e:
        return server_error(e, '2fa')


@two_factor_bp.route('/status', methods=['GET'])
@jwt_required()
def get_2fa_status():
    """Kullanıcının 2FA durumunu getir"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)

        if not user:
            return jsonify({'error': 'Kullanıcı bulunamadı'}), 404

        return jsonify({
            'two_factor_enabled': user.two_factor_enabled,
            'has_fcm_token': user.fcm_token is not None
        }), 200

    except Exception as e:
        return server_error(e, '2fa')