from models.category_model import Category


class CategoryRepository:

    @staticmethod
    def get_all():
        return Category.query.all()
