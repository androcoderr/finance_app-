from models.bill_model import Bill, BillPayment
from database.db import db
from sqlalchemy import and_
from datetime import datetime


class BillRepository:

    @staticmethod
    def get_all_by_user_id(user_id):
        """Kullanıcının tüm aktif faturalarını getirir."""
        return Bill.query.filter_by(user_id=user_id, is_active=True).all()

    @staticmethod
    def find_by_id(bill_id, user_id):
        """Belirli bir faturayı ID'ye göre bulur."""
        return Bill.query.filter_by(id=bill_id, user_id=user_id).first()

    @staticmethod
    def get_paid_bills_for_period(user_id, period):
        """Belirli bir dönemde ödenmiş faturaları getirir."""
        paid_bill_ids = db.session.query(BillPayment.bill_id).filter(
            BillPayment.period == period,
            Bill.user_id == user_id
        ).join(Bill, Bill.id == BillPayment.bill_id).distinct()
        return [b_id[0] for b_id in paid_bill_ids]

    @staticmethod
    def create(bill_data):
        """Yeni bir fatura oluşturur."""
        new_bill = Bill(**bill_data)
        db.session.add(new_bill)
        db.session.commit()
        return new_bill

    @staticmethod
    def update(bill, data):
        """Bir faturayı günceller."""
        for key, value in data.items():
            if hasattr(bill, key):
                setattr(bill, key, value)
        db.session.commit()
        return bill

    @staticmethod
    def delete(bill):
        """Bir faturayı siler."""
        db.session.delete(bill)
        db.session.commit()
        return True

    @staticmethod
    def create_payment(payment_data):
        """Bir fatura için ödeme kaydı oluşturur."""
        new_payment = BillPayment(**payment_data)
        db.session.add(new_payment)
        db.session.commit()
        return new_payment
