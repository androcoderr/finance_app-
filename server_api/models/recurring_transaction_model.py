from database.db import db
import uuid


class RecurringTransaction(db.Model):
    __tablename__ = 'recurring_transactions'

    # Temel Alanlar
    id = db.Column(db.String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String, db.ForeignKey('users.id'), nullable=False)
    amount = db.Column(db.Float, nullable=False)

    # Flutter Modeliyle Uyumlu Yeni/Düzenlenmiş Alanlar
    category_id = db.Column(db.String, db.ForeignKey('categories.id'), nullable=False)  # categoryId
    description = db.Column(db.String(255), nullable=True)  # description
    type = db.Column(db.String(10), nullable=False)  # type ('income' veya 'expense')

    start_date = db.Column(db.DateTime, nullable=False)  # startDate
    end_date = db.Column(db.DateTime, nullable=True)  # endDate (nullable olmalı)
    frequency = db.Column(db.String(50), nullable=False)  # frequency ('daily', 'weekly', 'monthly')

    # next_date, tekrar eden işlemlerin yönetimi (cron/scheduled job) için
    # arka planda tutmak isterseniz kalabilir, ancak zorunlu değildir.
    # next_date = db.Column(db.DateTime, nullable=True)

    def __init__(self, user_id, amount, category_id, description, type, start_date, end_date, frequency):
        self.user_id = user_id
        self.amount = amount
        self.category_id = category_id
        self.description = description
        self.type = type
        self.start_date = start_date
        self.end_date = end_date
        self.frequency = frequency

    def to_dict(self):
        """API yanıtı için JSON formatına dönüştürme metodu (Opsiyonel)"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'amount': self.amount,
            'category_id': self.category_id,
            'description': self.description,
            'type': self.type,
            'start_date': self.start_date.isoformat(),
            'end_date': self.end_date.isoformat() if self.end_date else None,
            'frequency': self.frequency,
        }