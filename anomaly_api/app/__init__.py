# app/__init__.py

from flask import Flask
from config import Config
from flask_jwt_extended import JWTManager # <-- YENİ İMPORT

# JWT Yöneticisini global olarak başlat
jwt = JWTManager()

def create_app(config_class=Config):
    """
    Flask Uygulama Fabrikası (Application Factory).
    Uygulamayı oluşturur, yapılandırır ve blueprint'leri kaydeder.
    """
    app = Flask(__name__)
    app.config.from_object(config_class)

    # --- YENİ EKLENEN BAŞLATMA KODU ---
    # JWT yöneticisini Flask uygulamasıyla ilişkilendir
    jwt.init_app(app)
    # --- ------------------------ ---

    # Modelin sunucu başladığında bir kez yüklenmesini sağla
    with app.app_context():
        try:
            from .services import anomaly_detection_service
            print("Anomali Tespiti Servisi başarıyla yüklendi ve hazır.")
        except Exception as e:
            print(f"KRİTİK HATA: Anomali Servisi yüklenemedi: {e}")
            
    # Routes (Blueprint) katmanını uygulamaya kaydet
    from .routes.anomaly_route import anomaly_bp
    app.register_blueprint(anomaly_bp)

    @app.route('/health')
    def health_check():
        """Sunucunun ayakta olduğunu kontrol etmek için basit bir endpoint."""
        return "OK - Anomaly Service"

    return app