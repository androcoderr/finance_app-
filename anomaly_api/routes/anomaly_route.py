# app/routes/anomaly_route.py

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
# Servisimizi import ediyoruz
from app.services.anomaly_detection_service import anomaly_service

# '/api/anomaly' önekiyle yeni bir Blueprint oluşturuyoruz
anomaly_bp = Blueprint('anomaly_api', __name__, url_prefix='/api/anomaly')

@anomaly_bp.route('/check-transaction', methods=['POST'])
@jwt_required()
def check_transaction_route():
    """
    Ana backend'den kullanıcının işlem geçmişini VE yeni işlemi alır.
    Bu yeni işleme göre anomali tespiti yapar.
    
    GİRDİ (Input) JSON Body:
    {
        "user_history": [
            {"date": "2025-10-20...", "amount": 100.0, "category": "Market", "type": "expense"},
            {"date": "2025-10-22...", "amount": 250.0, "category": "Alışveriş", "type": "expense"},
            ... (tüm geçmiş işlemler) ...
        ],
        "new_transaction": {
            "date": "2025-11-03T22:30:00", 
            "amount": 7000.0, 
            "category": "Alışveriş", 
            "type": "expense"
        }
    }
    """
    # Token'ı sadece yetkilendirme için kontrol ediyoruz
    current_user_id = get_jwt_identity() 
    data = request.get_json()
    
    # Gerekli tüm alanların geldiğinden emin ol
    if not data or 'user_history' not in data or 'new_transaction' not in data:
        return jsonify({"error": "Eksik parametreler: 'user_history' ve 'new_transaction' gereklidir."}), 400
    
    try:
        # Gelen veriyi değişkenlere ata
        user_history_list = data['user_history']
        new_transaction_dict = data['new_transaction']

        # Servisteki asıl anomali tespit fonksiyonunu çağır
        is_anomaly, message = anomaly_service.check_transaction(
            user_history_list,
            new_transaction_dict
        )
        
        # Başarılı tahmini döndür
        # ÇIKTI (Output) JSON:
        return jsonify({
            "is_anomaly": is_anomaly,
            "message": message,
            "user_id": current_user_id # Bilgi amaçlı
        }), 200

    except ValueError as e:
        # Servisten gelen (örn: "Yetersiz işlem geçmişi") hataları yakala
        # Bu bir anomali değil, sadece bir uyarı
        return jsonify({"is_anomaly": False, "message": str(e)}), 200
    except Exception as e:
        # Modelin çalışması sırasındaki beklenmedik hatalar
        print(f"HATA (Anomaly Route): {str(e)}")
        return jsonify({"error": "Anomali tespiti yapılırken bir sunucu hatası oluştu."}), 500