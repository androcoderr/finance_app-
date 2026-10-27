from database.db import db
from models.transaction_model import UserTransaction, TransactionType
from services.validation import parse_amount, parse_choice, parse_datetime, parse_text, require_category
import uuid


class TransactionRepository:
    @staticmethod
    def get_by_user_id(user_id):
        return UserTransaction.query.filter_by(user_id=user_id).all()

    @staticmethod
    def _clean(user_id, data, partial=False):
        """İstemci verisini doğrular; yalnızca izin verilen alanları döndürür."""
        out = {}
        if not partial or 'amount' in data:
            out['amount'] = parse_amount(data.get('amount'))
        if not partial or 'category_id' in data:
            out['category_id'] = require_category(data.get('category_id'))
        if not partial or 'description' in data:
            out['description'] = parse_text(data.get('description'), 'Açıklama', 255) or ''
        if not partial or 'date' in data:
            out['date'] = parse_datetime(data.get('date'))
        if not partial or 'type' in data:
            out['type'] = TransactionType[parse_choice(data.get('type'), 'İşlem türü', ('income', 'expense'))]
        if 'linked_goal_id' in data:
            goal_id = data.get('linked_goal_id')
            if goal_id:
                from models.goal_model import Goal
                if not isinstance(goal_id, str) or not Goal.query.filter_by(id=goal_id, user_id=user_id).first():
                    raise ValueError("Hedef bulunamadı")
            out['linked_goal_id'] = goal_id or None
        return out

    @staticmethod
    def create_for_user(user_id, transaction_data):
        fields = TransactionRepository._clean(user_id, transaction_data)
        transaction = UserTransaction(id=str(uuid.uuid4()), user_id=user_id, **fields)
        try:
            db.session.add(transaction)
            db.session.commit()
        except Exception:
            db.session.rollback()
            raise
        return transaction

    @staticmethod
    def update_for_user(user_id, transaction_id, data):
        transaction = UserTransaction.query.filter_by(id=transaction_id, user_id=user_id).first()
        if not transaction:
            return None
        # Sadece izin verilen alanlar değiştirilebilir (user_id/id gibi alanlar asla)
        for key, value in TransactionRepository._clean(user_id, data, partial=True).items():
            setattr(transaction, key, value)
        db.session.commit()
        return transaction

    @staticmethod
    def delete_for_user(user_id, transaction_id):
        transaction = UserTransaction.query.filter_by(id=transaction_id, user_id=user_id).first()
        if not transaction:
            return False
        db.session.delete(transaction)
        db.session.commit()
        return True