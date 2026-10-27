from repositories.category_repository import CategoryRepository


class CategoryService:
    def __init__(self):
        self.categoryRepository = CategoryRepository()

    def get_all_categories(self):
        return self.categoryRepository.get_all()
