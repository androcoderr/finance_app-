# recurring_transaction_service.py

from datetime import datetime
from repositories.recurring_transaction_repository import RecurringTransactionRepository


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