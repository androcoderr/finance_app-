from flask import jsonify


def server_error(e, where):
    """Beklenmeyen hatayı loglar; istemciye iç ayrıntı (SQL, dosya yolu vb.) sızdırmaz."""
    print(f"[{where}] {type(e).__name__}: {e}")
    return jsonify({"error": "Sunucu tarafında bir hata oluştu"}), 500
