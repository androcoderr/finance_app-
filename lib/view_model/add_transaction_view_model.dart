// lib/view_model/add_transaction_view_model.dart

import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import 'user_view_model.dart'; // UserViewModel'i import et

class AddTransactionViewModel extends ChangeNotifier {
  final TransactionService _service = TransactionService();

  // KRİTİK GÜNCELLEME: Token'a erişmek için UserViewModel'i al
  final UserViewModel _userViewModel;

  String? selectedCategory;
  int selectedTabIndex = 0; // 0 = expense, 1 = income
  bool isLoading = false;

  // Constructor'ı UserViewModel'i alacak şekilde güncelle
  AddTransactionViewModel(this._userViewModel);

  // Token'ı almak için bir yardımcı
  String? get _accessToken => _userViewModel.authToken;

  void setSelectedCategory(String? category) {
    selectedCategory = category;
    notifyListeners();
  }

  void setSelectedTabIndex(int index) {
    selectedTabIndex = index;
    selectedCategory = null;
    notifyListeners();
  }

  Future<bool> addTransaction({
    required String userId,
    required double amount,
    required String categoryId,
    String description = '',
  }) async {
    isLoading = true;
    notifyListeners();

    // KRİTİK GÜNCELLEME: Token'ı kontrol et
    final token = _accessToken;
    if (token == null) {
      print('Error: Token is null. User is not authenticated.');
      isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final type = selectedTabIndex == 0
          ? TransactionType.expense
          : TransactionType.income;

      final transaction = TransactionModel(
        id: '', // Backend oluşturacak
        userId: userId,
        amount: amount,
        categoryId: categoryId,
        description: description,
        date: DateTime.now(),
        type: type,
        linkedGoalId: null,
      );

      // KRİTİK GÜNCELLEME: Servis çağrısına token'ı ekle
      final success = await _service.addTransaction(transaction, token);

      isLoading = false;
      notifyListeners();

      if (success) {
        selectedCategory = null;
        notifyListeners();
      }

      return success;
    } catch (e) {
      print('Error in addTransaction: $e');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // İşlemleri getir
  Future<List<TransactionModel>> getTransactions(String userId) async {
    isLoading = true;
    notifyListeners();

    // KRİTİK GÜNCELLEME: Token'ı kontrol et
    final token = _accessToken;
    if (token == null) {
      print('Error: Token is null. User is not authenticated.');
      isLoading = false;
      notifyListeners();
      return [];
    }

    try {
      // KRİTİK GÜNCELLEME: Servis çağrısına token'ı ekle
      final transactions = await _service.getTransactions(userId, token);
      isLoading = false;
      notifyListeners();
      return transactions;
    } catch (e) {
      print('Error in getTransactions: $e');
      isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // İşlem güncelle
  Future<bool> updateTransaction({
    required String userId,
    required String transactionId,
    required TransactionModel transaction,
  }) async {
    isLoading = true;
    notifyListeners();

    // KRİTİK GÜNCELLEME: Token'ı kontrol et
    final token = _accessToken;
    if (token == null) {
      print('Error: Token is null. User is not authenticated.');
      isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      // KRİTİK GÜNCELLEME: Servis çağrısına token'ı ekle
      final success = await _service.updateTransaction(
        userId,
        transactionId,
        transaction,
        token, // Token'ı ekle
      );

      isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      print('Error in updateTransaction: $e');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // İşlem sil
  Future<bool> deleteTransaction({
    required String userId,
    required String transactionId,
  }) async {
    isLoading = true;
    notifyListeners();

    // KRİTİK GÜNCELLEME: Token'ı kontrol et
    final token = _accessToken;
    if (token == null) {
      print('Error: Token is null. User is not authenticated.');
      isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      // KRİTİK GÜNCELLEME: Servis çağrısına token'ı ekle
      final success = await _service.deleteTransaction(
        userId,
        transactionId,
        token, // Token'ı ekle
      );

      isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      print('Error in deleteTransaction: $e');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
