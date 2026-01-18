# recurring_transaction_repository.py

from database.db import db
from models.recurring_transaction_model import RecurringTransaction


class RecurringTransactionRepository:
    """
    Veritabanı CRUD işlemlerini yönetir.
    """

    def get_by_id(self, transaction_id):
        """Belirtilen ID'ye sahip işlemi getirir."""
        return RecurringTransaction.query.get(transaction_id)

    def get_all_by_user(self, user_id):
        """Belirtilen kullanıcıya ait tüm tekrar eden işlemleri getirir."""
        return RecurringTransaction.query.filter_by(user_id=user_id).all()

    def create(self, data):
        """Yeni bir tekrar eden işlem kaydı oluşturur."""
        try:
            new_transaction = RecurringTransaction(
                user_id=data['user_id'],
                amount=data['amount'],
                category_id=data['category_id'],
                description=data.get('description'),
                type=data['type'],
                start_date=data['start_date'],
                end_date=data.get('end_date'),
                frequency=data['frequency']
            )
            db.session.add(new_transaction)
            db.session.commit()
            return new_transaction
        except Exception as e:
            db.session.rollback()
            raise e

    def update(self, transaction, data):
        """Mevcut bir işlemi günceller."""
        try:
            transaction.amount = data.get('amount', transaction.amount)
            transaction.category_id = data.get('category_id', transaction.category_id)
            transaction.description = data.get('description', transaction.description)
            transaction.type = data.get('type', transaction.type)
            transaction.start_date = data.get('start_date', transaction.start_date)
            transaction.end_date = data.get('end_date', transaction.end_date)
            transaction.frequency = data.get('frequency', transaction.frequency)

            db.session.commit()
            return transaction
        except Exception as e:
            db.session.rollback()
            raise e

    def delete(self, transaction):
        """Belirtilen işlemi siler."""
        try:
            db.session.delete(transaction)
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            raise e