from repositories.bill_repository import BillRepository
from repositories.transaction_repository import TransactionRepository  # Entegrasyon için
import calendar
from datetime import datetime, timedelta
import uuid

from database.db import db
from models.bill_model import BillPayment
from models.category_model import Category
from models.transaction_model import UserTransaction, TransactionType
from services.validation import parse_amount, parse_text


class BillService:
    def __init__(self):
        self.bill_repo = BillRepository()
        self.transaction_repo = TransactionRepository()

    def get_bills_with_status(self, user_id):
        """Kullanıcının faturalarını durumlarına (bekliyor, gecikti) göre döndürür."""
        today = datetime.utcnow()
        current_period = today.strftime('%Y-%m')

        all_bills = self.bill_repo.get_all_by_user_id(user_id)
        paid_bill_ids = self.bill_repo.get_paid_bills_for_period(user_id, current_period)

        unpaid_bills = [bill for bill in all_bills if bill.id not in paid_bill_ids]

        categorized_bills = {
            'upcoming': [],
            'overdue': [],
            'paid': [],
        }

        # Ödeme günü bu ayda yoksa (31 Kasım, 30 Şubat...) ayın son gününe yuvarla
        last_day = calendar.monthrange(today.year, today.month)[1]
        today_date = today.date()

        for bill in unpaid_bills:
            due_date_this_month = today_date.replace(day=min(bill.due_day, last_day))
            days_diff = (due_date_this_month - today_date).days

            bill_info = bill.serialize()
            bill_info['days_diff'] = days_diff

            if days_diff < 0:
                bill_info['status'] = 'Gecikti'
                categorized_bills['overdue'].append(bill_info)
            else:
                bill_info['status'] = 'Bekliyor'
                categorized_bills['upcoming'].append(bill_info)

        for bill in all_bills:
            if bill.id in paid_bill_ids:
                bill_info = bill.serialize()
                bill_info['days_diff'] = 0
                bill_info['status'] = 'Ödendi'
                categorized_bills['paid'].append(bill_info)

        # Yaklaşanları tarihe göre sırala
        categorized_bills['upcoming'] = sorted(categorized_bills['upcoming'], key=lambda x: x['days_diff'])

        return categorized_bills

    @staticmethod
    def _validate(data, required=False):
        if 'name' in data or required:
            data['name'] = parse_text(data.get('name'), 'Fatura adı', 100, required=True)
        if 'amount' in data or required:
            data['amount'] = parse_amount(data.get('amount'))
        if 'due_day' in data or required:
            day = data.get('due_day')
            if isinstance(day, bool) or not isinstance(day, int) or not 1 <= day <= 31:
                raise ValueError("Ödeme günü 1 ile 31 arasında olmalıdır.")
        if 'category' in data or required:
            data['category'] = parse_text(data.get('category'), 'Kategori', 50, required=True)
        if 'recurrence' in data:
            data['recurrence'] = parse_text(data.get('recurrence'), 'Tekrar', 20) or 'Aylık'
        if 'is_active' in data and not isinstance(data['is_active'], bool):
            raise ValueError("is_active true/false olmalı.")

    def add_bill(self, user_id, data):
        """Yeni fatura ekler."""
        # Sadece izin verilen alanlar; sahibi her zaman token'daki kullanıcı
        data = {k: data[k] for k in ('name', 'amount', 'due_day', 'category', 'recurrence') if k in data}
        self._validate(data, required=True)
        data['user_id'] = user_id
        return self.bill_repo.create(data)

    def update_bill(self, user_id, bill_id, data):
        """Faturayı günceller."""
        bill = self.bill_repo.find_by_id(bill_id, user_id)
        if not bill:
            return None
        data = dict(data)
        self._validate(data)
        return self.bill_repo.update(bill, data)

    def delete_bill(self, user_id, bill_id):
        """Faturayı siler."""
        bill = self.bill_repo.find_by_id(bill_id, user_id)
        if not bill:
            return False
        return self.bill_repo.delete(bill)

    def mark_bill_as_paid(self, user_id, bill_id, data):
        """Bir faturayı ödendi olarak işaretler ve bir harcama işlemi oluşturur."""
        bill = self.bill_repo.find_by_id(bill_id, user_id)
        if not bill:
            raise ValueError("Fatura bulunamadı.")

        paid_amount = parse_amount(data.get('paid_amount'), 'Ödeme tutarı')

        payment_date = datetime.utcnow()
        period = payment_date.strftime('%Y-%m')

        if bill.id in self.bill_repo.get_paid_bills_for_period(user_id, period):
            raise ValueError("Bu fatura bu ay zaten ödendi.")

        # Fatura ödemeleri "Faturalar" gider kategorisine yazılır
        category = Category.query.filter_by(name='Faturalar', is_income=False).first()
        if not category:
            raise ValueError("Faturalar kategorisi bulunamadı.")

        # Ödeme kaydı ve gider işlemi tek seferde kaydedilir: ya ikisi ya hiçbiri
        payment_record = BillPayment(
            bill_id=bill.id,
            period=period,
            paid_amount=paid_amount,
            payment_date=payment_date,
        )
        transaction = UserTransaction(
            id=str(uuid.uuid4()),
            user_id=user_id,
            amount=paid_amount,
            category_id=category.id,
            description=f"{bill.name} - {period} faturası",
            date=payment_date,
            type=TransactionType.expense,
        )
        try:
            db.session.add(payment_record)
            db.session.add(transaction)
            db.session.commit()
        except Exception:
            db.session.rollback()
            raise

        return payment_record
