import 'package:flutter/material.dart';
import '../models/bill_model.dart';
import '../services/bill_service.dart';
import '../utils/error_handler.dart';

class BillsViewModel extends ChangeNotifier {
  List<UpcomingBill> _upcomingBills = [];
  List<UpcomingBill> _overdueBills = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UpcomingBill> get upcomingBills => _upcomingBills;
  List<UpcomingBill> get overdueBills => _overdueBills;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Token, View tarafından sağlanacak
  Future<void> fetchBills(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await BillService.getBills(token);
      _upcomingBills = response.upcoming;
      _overdueBills = response.overdue;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBill(Bill bill, String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      await BillService.createBill(bill, token);
      await fetchBills(token); // Listeyi yenile
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markAsPaid(String billId, double amount, String token) async {
    try {
      await BillService.payBill(billId, amount, token);
      // Sadece ilgili faturayı listeden çıkarmak daha verimli
      _upcomingBills.removeWhere((bill) => bill.id == billId);
      _overdueBills.removeWhere((bill) => bill.id == billId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeBill(String billId, String token) async {
    try {
      await BillService.deleteBill(billId, token);
      _upcomingBills.removeWhere((bill) => bill.id == billId);
      _overdueBills.removeWhere((bill) => bill.id == billId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }
}
