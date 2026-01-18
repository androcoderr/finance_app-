from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from services.category_service import CategoryService
from services.rbac_service import require_role

category_bp = Blueprint('category_bp', __name__, url_prefix='/categories')
categoryService = CategoryService()

@category_bp.route('', methods=['GET'])
def get_categories():
    categories = categoryService.get_all_categories()
    return jsonify([c.serialize() for c in categories])

@category_bp.route('/<category_id>', methods=['GET'])
def get_category(category_id):
    category = categoryService.get_category_by_id(category_id)
    if not category:
        return {"error": "Category not found"}, 404
    return jsonify(category.serialize())

@category_bp.route('', methods=['POST'])
@jwt_required()
@require_role('ADMIN')
def create_category():
    data = request.get_json()
    category = categoryService.create_category(data)
    return jsonify(category.serialize()), 201

@category_bp.route('/<category_id>', methods=['PUT'])
@jwt_required()
@require_role('ADMIN')
def update_category(category_id):
    data = request.get_json()
    category = categoryService.update_category(category_id, data)
    if not category:
        return {"error": "Category not found"}, 404
    return jsonify(category.serialize())

@category_bp.route('/<category_id>', methods=['DELETE'])
@jwt_required()
@require_role('ADMIN')
def delete_category(category_id):
    success = categoryService.delete_category(category_id)
    if not success:
        return {"error": "Category not found"}, 404
    return '', 204