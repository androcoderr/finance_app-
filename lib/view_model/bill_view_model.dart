import 'package:flutter/material.dart';
import '../models/bill_model.dart';
import '../services/bill_reminder_service.dart';
import '../services/bill_service.dart';
import '../utils/error_handler.dart';

class BillsViewModel extends ChangeNotifier {
  List<UpcomingBill> _upcomingBills = [];
  List<UpcomingBill> _overdueBills = [];
  List<UpcomingBill> _paidBills = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UpcomingBill> get upcomingBills => _upcomingBills;
  List<UpcomingBill> get overdueBills => _overdueBills;
  List<UpcomingBill> get paidBills => _paidBills;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> syncReminders() => BillReminders.sync(
        unpaid: [..._overdueBills, ..._upcomingBills],
        paidThisMonth: _paidBills,
      );

  // Token, View tarafından sağlanacak
  Future<void> fetchBills(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await BillService.getBills(token);
      _upcomingBills = response.upcoming;
      _overdueBills = response.overdue;
      _paidBills = response.paid;
      // Hatırlatmalar açıksa güncel listeye göre yeniden kurulur
      syncReminders();
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
      _actionError = _messageOf(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Ödeme/silme/güncelleme hataları sayfayı hata ekranına çevirmez;
  // ekranda SnackBar ile gösterilir
  String? _actionError;
  String? get actionError => _actionError;

  String _messageOf(Object e) =>
      e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e';

  Future<bool> updateBill(String billId, Bill bill, String token) async {
    try {
      await BillService.updateBill(billId, bill, token);
      await fetchBills(token);
      return true;
    } catch (e) {
      _actionError = _messageOf(e);
      return false;
    }
  }

  Future<bool> markAsPaid(String billId, double amount, String token) async {
    try {
      await BillService.payBill(billId, amount, token);
      await fetchBills(token); // Fatura "Ödenen" sekmesine geçsin
      return true;
    } catch (e) {
      _actionError = _messageOf(e);
      return false;
    }
  }

  Future<bool> removeBill(String billId, String token) async {
    try {
      await BillService.deleteBill(billId, token);
      _upcomingBills.removeWhere((bill) => bill.id == billId);
      _overdueBills.removeWhere((bill) => bill.id == billId);
      _paidBills.removeWhere((bill) => bill.id == billId);
      syncReminders(); // Silinen faturanın hatırlatması kalmasın
      notifyListeners();
      return true;
    } catch (e) {
      _actionError = _messageOf(e);
      return false;
    }
  }
}
