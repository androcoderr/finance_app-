from database.db import db
from models.transaction_model import UserTransaction, TransactionType
from sqlalchemy.exc import IntegrityError
from datetime import datetime
import uuid


class TransactionRepository:
    @staticmethod
    def get_by_user_id(user_id):
        return UserTransaction.query.filter_by(user_id=user_id).all()

    @staticmethod
    def create_for_user(user_id, transaction_data):
        try:
            print(f"[DEBUG] transaction_data: {transaction_data}")

            # Direkt UserTransaction objesi oluştur
            transaction = UserTransaction(
                id=str(uuid.uuid4()),
                user_id=user_id,
                amount=transaction_data['amount'],
                category_id=transaction_data['category_id'],
                description=transaction_data.get('description', ''),
                date=datetime.fromisoformat(transaction_data['date'].replace('Z', '+00:00')),
                type=TransactionType[transaction_data['type']],
                linked_goal_id=transaction_data.get('linked_goal_id')
            )

            db.session.add(transaction)
            db.session.commit()

            print(f"[SUCCESS] Transaction created: {transaction.id}")
            return transaction

        except IntegrityError as e:
            db.session.rollback()
            raise ValueError(f"Database error: {str(e)}")
        except Exception as e:
            db.session.rollback()
            raise ValueError(f"Error: {str(e)}")

    @staticmethod
    def update_for_user(user_id, transaction_id, data):
        transaction = UserTransaction.query.filter_by(id=transaction_id, user_id=user_id).first()
        if not transaction:
            return None
        for key, value in data.items():
            if hasattr(transaction, key) and key != 'id':
                if key == 'type':
                    value = TransactionType[value]
                elif key == 'date':
                    value = datetime.fromisoformat(value.replace('Z', '+00:00'))
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