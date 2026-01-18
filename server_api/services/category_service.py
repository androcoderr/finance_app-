from repositories.category_repository import CategoryRepository

class CategoryService:
    def __init__(self):
        self.categoryRepository = CategoryRepository()

    def get_all_categories(self):
        return self.categoryRepository.get_all()

    def get_category_by_id(self, category_id):
        return self.categoryRepository.get_by_id(category_id)

    def create_category(self, data):
        return self.categoryRepository.create(data)

    def update_category(self, category_id, data):
        return self.categoryRepository.update(category_id, data)

    def delete_category(self, category_id):
        return self.categoryRepository.delete(category_id)