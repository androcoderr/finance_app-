from database.db import db
import uuid

class Category(db.Model):
    __tablename__ = 'categories'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = db.Column(db.String(100), nullable=False)
    is_income = db.Column(db.Boolean, nullable=False)

    def serialize(self):
        return {
            "id": self.id,
            "name": self.name,
            "is_income": self.is_income
        }
