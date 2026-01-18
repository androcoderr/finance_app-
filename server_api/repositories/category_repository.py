from database.db import db
from models.category_model import Category

class CategoryRepository:

    @staticmethod
    def get_all():
        return Category.query.all()

    @staticmethod
    def get_by_id(category_id):
        return Category.query.get(category_id)

    @staticmethod
    def create(category_data):
        category = Category(**category_data)
        db.session.add(category)
        db.session.commit()
        return category

    @staticmethod
    def update(category_id, data):
        category = Category.query.get(category_id)
        if not category:
            return None
        for key, value in data.items():
            if hasattr(category, key):
                setattr(category, key, value)
        db.session.commit()
        return category

    @staticmethod
    def delete(category_id):
        category = Category.query.get(category_id)
        if not category:
            return False
        db.session.delete(category)
        db.session.commit()
        return True