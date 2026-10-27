"""Uygulama sürüm kontrolü: açılışta sorulur; ayrıca her istekte X-App-Version-Code başlığı denetlenir.

Platform: X-App-Platform başlığı veya ?platform= (android | ios). Gelmezse android sayılır
(ilk Android istemcileri platform göndermiyor). Her platformun MIN/LATEST değeri ve mağaza bağlantısı ayrıdır.
"""
from flask import Blueprint, current_app, jsonify, request

app_config_bp = Blueprint('app_config_bp', __name__, url_prefix='/app')

VERSION_HEADER = 'X-App-Version-Code'
PLATFORM_HEADER = 'X-App-Platform'
UPDATE_MESSAGE = "Uygulamanın yeni bir sürümü var. Devam etmek için lütfen güncelleyin."


def _parse_version(value):
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def _platform():
    value = (request.args.get('platform') or request.headers.get(PLATFORM_HEADER) or 'android').strip().lower()
    return 'ios' if value == 'ios' else 'android'


def _platform_settings(platform):
    """(min, latest, store_url) — store_url boşsa None (istemci mağazayı kendi açar)."""
    cfg = current_app.config
    if platform == 'ios':
        min_code, latest, url = cfg['IOS_MIN_APP_VERSION_CODE'], cfg['IOS_LATEST_APP_VERSION_CODE'], cfg['APP_STORE_URL']
    else:
        min_code, latest, url = cfg['MIN_APP_VERSION_CODE'], cfg['LATEST_APP_VERSION_CODE'], cfg['PLAY_STORE_URL']
    return min_code, max(latest, min_code), (url or None)


@app_config_bp.route('/config', methods=['GET'])
def app_config():
    """GET /app/config?platform=android|ios&version_code=N → güncelleme gerekli mi / önerilir mi."""
    platform = _platform()
    version = _parse_version(request.args.get('version_code') or request.headers.get(VERSION_HEADER))
    min_code, latest_code, store_url = _platform_settings(platform)
    return jsonify({
        "platform": platform,
        "min_version_code": min_code,
        "latest_version_code": latest_code,
        "update_required": version is not None and version < min_code,
        "update_available": version is not None and version < latest_code,
        "store_url": store_url,
        "message": UPDATE_MESSAGE,
    }), 200


def enforce_min_version():
    """before_request: başlığı olan ve kendi platformunun MIN'inin altında kalan uygulamaya 426 döner.
    Başlıksız istekler (tarayıcıdaki sıfırlama/gizlilik sayfaları, sağlık kontrolü) etkilenmez."""
    if request.path in ('/health', '/app/config'):
        return None
    version = _parse_version(request.headers.get(VERSION_HEADER))
    if version is None:
        return None
    min_code, _, store_url = _platform_settings(_platform())
    if version < min_code:
        return jsonify({
            "error": UPDATE_MESSAGE,
            "update_required": True,
            "store_url": store_url,
        }), 426
    return None
