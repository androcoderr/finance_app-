// lib/viewmodels/recurring_transaction_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/recurring_transaction_model.dart';
import '../services/recurring_transaction_service.dart';

class RecurringTransactionViewModel extends ChangeNotifier {
  List<RecurringTransaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<RecurringTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<RecurringTransaction> get expenseTransactions =>
      _transactions.where((t) => t.type == 'expense').toList();

  List<RecurringTransaction> get incomeTransactions =>
      _transactions.where((t) => t.type == 'income').toList();

  Future<void> loadTransactions(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Yükleme durumunu UI'a bildir

    try {
      // Servisi çağırırken BuildContext'i iletiyoruz
      _transactions =
          await RecurringTransactionService.getRecurringTransactions();
    } catch (e) {
      // Token Expired hatası zaten yönlendirme yaptığı için, diğer hataları gösteririz.
      if (!e.toString().contains('Token Expired')) {
        _error = e.toString().contains('Exception:')
            ? e.toString().split('Exception: ')[1]
            : e.toString();
      }
      debugPrint('❌ Load Transactions Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // Yükleme bitti veya hata oluştu, UI'ı tekrar bildir
    }
  }
}
