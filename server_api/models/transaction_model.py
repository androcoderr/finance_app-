from database.db import db
from sqlalchemy.dialects.postgresql import ENUM
import enum
import uuid

class TransactionType(enum.Enum):
    income = "income"
    expense = "expense"

class UserTransaction(db.Model):
    __tablename__ = 'transactions'

    id = db.Column(db.String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String, db.ForeignKey('users.id'), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    category_id = db.Column(db.String, db.ForeignKey('categories.id'), nullable=False)
    description = db.Column(db.String(255))
    date = db.Column(db.DateTime, nullable=False)
    type = db.Column(ENUM(TransactionType), nullable=False)
    linked_goal_id = db.Column(db.String, db.ForeignKey('goals.id'), nullable=True)


    def serialize(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "amount": self.amount,
            "category_id": self.category_id,
            "description": self.description,
            "date": self.date.isoformat(),
            "type": self.type.value,
            "linked_goal_id": self.linked_goal_id
        }
