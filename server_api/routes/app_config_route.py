"""Uygulama sürüm kontrolü: açılışta sorulur; ayrıca her istekte X-App-Version-Code başlığı denetlenir."""
from flask import Blueprint, current_app, jsonify, request

app_config_bp = Blueprint('app_config_bp', __name__, url_prefix='/app')

VERSION_HEADER = 'X-App-Version-Code'
UPDATE_MESSAGE = "Uygulamanın yeni bir sürümü var. Devam etmek için lütfen güncelleyin."


def _parse_version(value):
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


@app_config_bp.route('/config', methods=['GET'])
def app_config():
    """GET /app/config?version_code=N → güncelleme gerekli mi / önerilir mi."""
    cfg = current_app.config
    version = _parse_version(request.args.get('version_code') or request.headers.get(VERSION_HEADER))
    min_code, latest_code = cfg['MIN_APP_VERSION_CODE'], cfg['LATEST_APP_VERSION_CODE']
    return jsonify({
        "min_version_code": min_code,
        "latest_version_code": max(latest_code, min_code),
        "update_required": version is not None and version < min_code,
        "update_available": version is not None and version < max(latest_code, min_code),
        "store_url": cfg['PLAY_STORE_URL'],
        "message": UPDATE_MESSAGE,
    }), 200


def enforce_min_version():
    """before_request: başlığı olan ve MIN'in altında kalan uygulamaya 426 döner.
    Başlıksız istekler (tarayıcıdaki sıfırlama/gizlilik sayfaları, sağlık kontrolü) etkilenmez."""
    if request.path in ('/health', '/app/config'):
        return None
    version = _parse_version(request.headers.get(VERSION_HEADER))
    if version is not None and version < current_app.config['MIN_APP_VERSION_CODE']:
        return jsonify({
            "error": UPDATE_MESSAGE,
            "update_required": True,
            "store_url": current_app.config['PLAY_STORE_URL'],
        }), 426
    return None
