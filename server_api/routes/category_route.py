from flask import Blueprint, jsonify
from services.category_service import CategoryService

category_bp = Blueprint('category_bp', __name__, url_prefix='/categories')
categoryService = CategoryService()


@category_bp.route('', methods=['GET'])
def get_categories():
    """Sabit kategori listesi (sunucu açılışında eklenir; kullanıcıya özel veri içermez)."""
    categories = categoryService.get_all_categories()
    return jsonify([c.serialize() for c in categories])
