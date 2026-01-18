from database.db import db
import uuid
from datetime import datetime

class Bill(db.Model):
    __tablename__ = 'bills'

    id = db.Column(db.String, primary_key=True, default=lambda: f"FAT_{uuid.uuid4().hex[:6].upper()}")
    user_id = db.Column(db.String, db.ForeignKey('users.id'), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    amount = db.Column(db.Float, nullable=False) # 0 for variable amount
    due_day = db.Column(db.Integer, nullable=False) # Day of the month
    category = db.Column(db.String(50), nullable=False)
    recurrence = db.Column(db.String(20), default='Aylık')
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    payments = db.relationship('BillPayment', backref='bill', lazy=True, cascade="all, delete-orphan")

    def serialize(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "name": self.name,
            "amount": self.amount,
            "due_day": self.due_day,
            "category": self.category,
            "recurrence": self.recurrence,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat()
        }

class BillPayment(db.Model):
    __tablename__ = 'bill_payments'

    id = db.Column(db.String, primary_key=True, default=lambda: f"PAY_{uuid.uuid4().hex[:6].upper()}")
    bill_id = db.Column(db.String, db.ForeignKey('bills.id'), nullable=False)
    period = db.Column(db.String(7), nullable=False) # YYYY-MM
    paid_amount = db.Column(db.Float, nullable=False)
    payment_date = db.Column(db.DateTime, nullable=False)
    status = db.Column(db.String(20), default='Ödendi') # Ödendi

    def serialize(self):
        return {
            "id": self.id,
            "bill_id": self.bill_id,
            "period": self.period,
            "paid_amount": self.paid_amount,
            "payment_date": self.payment_date.isoformat(),
            "status": self.status
        }
