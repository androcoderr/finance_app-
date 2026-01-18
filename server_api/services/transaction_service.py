from repositories.transaction_repository import TransactionRepository

class TransactionService:
    def __init__(self):
        self.transactionRepository = TransactionRepository()

    def add_transaction_for_user(self, user_id, data):
        return self.transactionRepository.create_for_user(user_id, data)

    def update_transaction_for_user(self, user_id, transaction_id, data):
        return self.transactionRepository.update_for_user(user_id, transaction_id, data)

    def delete_transaction_for_user(self, user_id, transaction_id):
        return self.transactionRepository.delete_for_user(user_id, transaction_id)

    def get_transactions_by_user(self, user_id):
        return self.transactionRepository.get_by_user_id(user_id)


