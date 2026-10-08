# recurring_transaction_service.py

import calendar
from datetime import date, datetime, time, timedelta

from database.db import db
from models.category_model import Category
from models.recurring_transaction_model import RecurringTransaction
from models.transaction_model import TransactionType, UserTransaction
from repositories.recurring_transaction_repository import RecurringTransactionRepository

# Tek seferde oluşturulacak en fazla tekrar (ör. yıllar önce başlayan günlük işlem)
_MAX_OCCURRENCES = 1000


def _add_months(d, months):
    """Ay ekler; gün o ayda yoksa ayın son gününe yuvarlar (31 Ocak + 1 ay = 28/29 Şubat)."""
    m = d.month - 1 + months
    year, month = d.year + m // 12, m % 12 + 1
    return date(year, month, min(d.day, calendar.monthrange(year, month)[1]))


def occurrence_dates(start, frequency, after, until):
    """start'tan itibaren, after'dan sonra ve until'e kadar (dahil) tekrar tarihleri."""
    out = []
    for n in range(100000):
        if frequency == 'daily':
            d = start + timedelta(days=n)
        elif frequency == 'weekly':
            d = start + timedelta(weeks=n)
        elif frequency == 'monthly':
            d = _add_months(start, n)
        elif frequency == 'yearly':
            d = _add_months(start, 12 * n)
        else:
            break
        if d > until:
            break
        if after is None or d > after:
            out.append(d)
            if len(out) >= _MAX_OCCURRENCES:
                break
    return out


class RecurringTransactionService:
    """
    Tekrar eden işlemlerin iş mantığını yönetir.
    """

    def __init__(self):
        self.repo = RecurringTransactionRepository()

    def _prepare_data(self, data):
        """JSON verisindeki tarih dizilerini DateTime objelerine dönüştürür."""

        # 'startDate' zorunlu
        data['start_date'] = datetime.strptime(data['start_date'], '%Y-%m-%dT%H:%M:%S.%f')  # ISO 8601 formatı

        # 'endDate' opsiyonel
        end_date_str = data.get('end_date')
        if end_date_str:
            # Eğer 'end_date' varsa, onu da DateTime objesine dönüştür.
            data['end_date'] = datetime.strptime(end_date_str, '%Y-%m-%dT%H:%M:%S.%f')
        else:
            # Eğer 'end_date' yoksa, None olarak ayarla.
            data['end_date'] = None

        return data

    @staticmethod
    def materialize_due(user_id):
        """Vadesi gelmiş tekrarları gerçek işlem olarak oluşturur.
        Böylece bakiye, aylık toplamlar, grafikler ve raporlar tutarlı olur."""
        today = date.today()
        # Aynı anda gelen iki istek aynı tekrarı iki kez oluşturmasın
        recurring = (RecurringTransaction.query.filter_by(user_id=user_id)
                     .with_for_update().all())
        created = 0
        for r in recurring:
            until = min(today, r.end_date.date()) if r.end_date else today
            dates = occurrence_dates(r.start_date.date(), r.frequency, r.last_generated, until)
            if not dates:
                continue
            description = r.description
            if not description:
                category = db.session.get(Category, r.category_id)
                description = f"{category.name if category else 'İşlem'} (tekrarlayan)"
            for d in dates:
                db.session.add(UserTransaction(
                    user_id=user_id,
                    amount=r.amount,
                    category_id=r.category_id,
                    description=description,
                    date=datetime.combine(d, time(12, 0)),
                    type=TransactionType[r.type],
                ))
            r.last_generated = dates[-1]
            created += len(dates)
        db.session.commit()
        return created

    def get_transaction(self, transaction_id):
        return self.repo.get_by_id(transaction_id)

    def get_user_transactions(self, user_id):
        transactions = self.repo.get_all_by_user(user_id)
        # to_dict metodu kullanılarak JSON formatına dönüştürülür (Model'de tanımlanan)
        return [t.to_dict() for t in transactions]

    def create_transaction(self, user_id, data):
        # user_id'yi veriye ekle
        data['user_id'] = user_id

        # Veri formatını hazırla (tarih çevrimleri)
        processed_data = self._prepare_data(data)

        return self.repo.create(processed_data).to_dict()

    def update_transaction(self, transaction_id, data):
        transaction = self.repo.get_by_id(transaction_id)
        if not transaction:
            return None

        # Sadece güncellenecek alanları hazırla ve tarihleri çevir
        if 'start_date' in data or 'end_date' in data:
            data = self._prepare_data(data)

        return self.repo.update(transaction, data).to_dict()

    def delete_transaction(self, transaction_id):
        transaction = self.repo.get_by_id(transaction_id)
        if not transaction:
            return False
        self.repo.delete(transaction)
        return True