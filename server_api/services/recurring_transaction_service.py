# recurring_transaction_service.py

import calendar
from datetime import date, datetime, time, timedelta

from database.db import db
from models.category_model import Category
from models.recurring_transaction_model import RecurringTransaction
from models.transaction_model import TransactionType, UserTransaction
from repositories.recurring_transaction_repository import RecurringTransactionRepository
from services.validation import parse_amount, parse_choice, parse_datetime, parse_text, require_category

# Tek seferde oluşturulacak en fazla tekrar (ör. yıllar önce başlayan günlük işlem)
_MAX_OCCURRENCES = 1000
_MAX_PER_USER = 100
_MAX_PAST_DAYS = 366
_TYPES = ('income', 'expense')
_FREQUENCIES = ('daily', 'weekly', 'monthly', 'yearly')


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

    def _prepare_data(self, data, existing=None):
        """İstemci verisini doğrular; yalnızca izin verilen alanları döndürür.
        existing verilirse (güncelleme) eksik alanlar mevcut kayıttan alınır."""
        def pick(key):
            if key in data:
                return data[key]
            return getattr(existing, key) if existing is not None else None

        out = {
            'amount': parse_amount(pick('amount')),
            'category_id': require_category(pick('category_id')),
            'description': parse_text(pick('description'), 'Açıklama', 255),
            'type': parse_choice(pick('type'), 'İşlem türü', _TYPES),
            'frequency': parse_choice(pick('frequency'), 'Tekrar sıklığı', _FREQUENCIES),
        }

        start = data.get('start_date') if 'start_date' in data else (existing.start_date if existing else None)
        start = parse_datetime(start, 'Başlangıç tarihi') if isinstance(start, str) else start
        if start is None:
            raise ValueError("Başlangıç tarihi gerekli.")
        # Çok eski başlangıç geçmişe yüzlerce işlem yazar; yalnızca yeni/değişen tarih için kontrol edilir
        changed = existing is None or start != existing.start_date
        if changed and start.date() < date.today() - timedelta(days=_MAX_PAST_DAYS):
            raise ValueError("Başlangıç tarihi en fazla 1 yıl önce olabilir.")
        if start.year > date.today().year + 50:
            raise ValueError("Başlangıç tarihi geçersiz.")
        out['start_date'] = start

        end = data.get('end_date') if 'end_date' in data else (existing.end_date if existing else None)
        end = parse_datetime(end, 'Bitiş tarihi') if isinstance(end, str) and end else (end or None)
        if end is not None and end < start:
            raise ValueError("Bitiş tarihi başlangıçtan önce olamaz.")
        out['end_date'] = end
        return out

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
        if RecurringTransaction.query.filter_by(user_id=user_id).count() >= _MAX_PER_USER:
            raise ValueError(f"En fazla {_MAX_PER_USER} tekrarlayan işlem eklenebilir.")
        processed_data = self._prepare_data(data)
        processed_data['user_id'] = user_id  # sahibi her zaman token'daki kullanıcı
        return self.repo.create(processed_data).to_dict()

    def update_transaction(self, transaction_id, data):
        transaction = self.repo.get_by_id(transaction_id)
        if not transaction:
            return None

        return self.repo.update(transaction, self._prepare_data(data, existing=transaction)).to_dict()

    def delete_transaction(self, transaction_id):
        transaction = self.repo.get_by_id(transaction_id)
        if not transaction:
            return False
        self.repo.delete(transaction)
        return True