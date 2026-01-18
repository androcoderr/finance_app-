from repositories.bill_repository import BillRepository
from repositories.transaction_repository import TransactionRepository  # Entegrasyon için
from datetime import datetime, timedelta


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
            'overdue': []
        }

        for bill in unpaid_bills:
            due_date_this_month = today.replace(day=bill.due_day)
            days_diff = (due_date_this_month - today).days

            bill_info = bill.serialize()
            bill_info['days_diff'] = days_diff

            if days_diff < 0:
                bill_info['status'] = 'Gecikti'
                categorized_bills['overdue'].append(bill_info)
            else:
                bill_info['status'] = 'Bekliyor'
                categorized_bills['upcoming'].append(bill_info)

        # Yaklaşanları tarihe göre sırala
        categorized_bills['upcoming'] = sorted(categorized_bills['upcoming'], key=lambda x: x['days_diff'])

        return categorized_bills

    def add_bill(self, user_id, data):
        """Yeni fatura ekler."""
        data['user_id'] = user_id
        return self.bill_repo.create(data)

    def update_bill(self, user_id, bill_id, data):
        """Faturayı günceller."""
        bill = self.bill_repo.find_by_id(bill_id, user_id)
        if not bill:
            return None
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

        paid_amount = data.get('paid_amount')
        if not paid_amount or paid_amount <= 0:
            raise ValueError("Geçerli bir ödeme tutarı girilmelidir.")

        payment_date = datetime.utcnow()
        period = payment_date.strftime('%Y-%m')

        # 1. Ödeme kaydını oluştur
        payment_data = {
            'bill_id': bill.id,
            'period': period,
            'paid_amount': paid_amount,
            'payment_date': payment_date
        }
        payment_record = self.bill_repo.create_payment(payment_data)

        # 2. Ana Transaction tablosuna harcama olarak ekle
        transaction_data = {
            'user_id': user_id,
            'amount': paid_amount,
            'category_id': bill.category,  # Kategori adını ID olarak varsayıyoruz, gerekirse eşleştirme yapılmalı
            'description': f"{bill.name} - {period} Faturası",
            'date': payment_date.isoformat(),
            'type': 'expense'  # TransactionType enum'una göre
        }
        self.transaction_repo.create_for_user(user_id, transaction_data)

        return payment_record
