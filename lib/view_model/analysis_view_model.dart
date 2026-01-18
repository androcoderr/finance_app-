// lib/view_model/analysis_view_model.dart

import 'package:flutter/cupertino.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import 'package:collection/collection.dart';
import 'user_view_model.dart'; // GÜNCELLEME 1: UserViewModel'i import et

// YENİ: UI'da kullanılacak tarih filtresi seçenekleri
enum DateFilter { thisMonth, lastMonth, last3Months }

class AnalysisViewModel extends ChangeNotifier {
  final TransactionService _service = TransactionService();

  // GÜNCELLEME 2: UserViewModel'i tutmak için değişken ekle
  final UserViewModel _userViewModel;

  // Dispose kontrolü için flag
  bool _disposed = false;

  List<TransactionModel> _allTransactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  DateFilter _currentFilter = DateFilter.thisMonth;
  DateFilter get currentFilter => _currentFilter;

  double totalIncome = 0.0;
  double totalExpense = 0.0;
  double netBalance = 0.0;
  Map<String, double> expenseSummary = {};
  Map<String, double> incomeSummary = {};

  double previousPeriodExpense = 0.0;
  double? expenseChangePercentage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // GÜNCELLEME 3: Token'a erişmek için getter ekle
  String? get _accessToken => _userViewModel.authToken;
  String? get _userId => _userViewModel.userId;

  // GÜNCELLEME 4: Constructor'ı UserViewModel'i alacak şekilde güncelle
  AnalysisViewModel(this._userViewModel);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  // MARK: - Veri Yükleme ve İşleme

  // GÜNCELLEME 5: Metot imzası değişti, artık 'userId' almıyor (UserViewModel'den alacak)
  Future<void> loadAnalysisData() async {
    if (_disposed) return;

    _isLoading = true;
    _errorMessage = null;
    if (!_disposed) notifyListeners();

    // GÜNCELLEME 6: Token ve UserId'yi ViewModel'den al
    final token = _accessToken;
    final userId = _userId;

    // Token yoksa hata dön
    if (token == null || userId == null) {
      _errorMessage =
          "Kullanıcı oturumu bulunamadı. Lütfen tekrar giriş yapın.";
      _isLoading = false;
      if (!_disposed) notifyListeners();
      return;
    }

    try {
      // GÜNCELLEME 7: Servis çağrısına token eklendi
      _allTransactions = await _service.getTransactions(userId, token);

      if (_disposed) return;

      _processTransactions();
    } catch (e) {
      if (_disposed) return;
      _errorMessage = 'İşlemler yüklenirken hata oluştu: ${e.toString()}';
      debugPrint('AnalysisViewModel Error: $e');
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // YENİ: UI'dan filtreyi değiştirmek için kullanılacak metot
  void changeFilter(DateFilter newFilter) {
    if (_disposed) return;
    if (_currentFilter == newFilter) return;

    _currentFilter = newFilter;
    _isLoading = true;
    if (!_disposed) notifyListeners();

    _processTransactions();

    if (!_disposed) {
      _isLoading = false;
      notifyListeners();
    }
  }

  // GÜNCELLENDİ: Bu metot artık seçilen filtreye göre tarih aralığı belirleyip hesaplama yapıyor.
  void _processTransactions() {
    if (_disposed) return;

    // ... (BU METODUN İÇİNDE HİÇBİR DEĞİŞİKLİK YOK, MÜKEMMEL ÇALIŞIYOR) ...
    // ... (Tüm hesaplamaları _allTransactions üzerinden yaptığı için) ...

    // Hesaplamadan önce tüm değerleri sıfırla
    totalIncome = 0.0;
    totalExpense = 0.0;
    expenseSummary = {};
    incomeSummary = {};
    previousPeriodExpense = 0.0;
    expenseChangePercentage = null;

    final now = DateTime.now().toLocal();
    late DateTime startDate;
    late DateTime endDate;
    late DateTime prevStartDate;
    late DateTime prevEndDate;

    // Seçili filtreye göre tarih aralıklarını belirle
    switch (_currentFilter) {
      case DateFilter.thisMonth:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        prevStartDate = DateTime(now.year, now.month - 1, 1);
        prevEndDate = startDate;
        break;
      case DateFilter.lastMonth:
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 1);
        prevStartDate = DateTime(now.year, now.month - 2, 1);
        prevEndDate = startDate;
        break;
      case DateFilter.last3Months:
        // GÜNCELLEME: Küçük bir mantık hatası düzeltmesi
        // Son 3 ay: (Mevcut ay - 2)'nin başından, (Mevcut ay + 1)'in başına kadar
        startDate = DateTime(now.year, now.month - 2, 1);
        endDate = DateTime(
          now.year,
          now.month + 1,
          0,
          23,
          59,
          59,
        ); // Ayın sonunu al
        // Önceki 3 ay: (Mevcut ay - 5)'in başından, (Mevcut ay - 2)'nin başına kadar
        prevStartDate = DateTime(now.year, now.month - 5, 1);
        prevEndDate = startDate;
        break;
    }

    // Mevcut dönem işlemlerini filtrele
    final currentPeriodTransactions = _allTransactions
        .where((t) => !t.date.isBefore(startDate) && t.date.isBefore(endDate))
        .toList();

    // Önceki dönem işlemlerini filtrele (karşılaştırma için)
    final previousPeriodTransactions = _allTransactions
        .where(
          (t) =>
              !t.date.isBefore(prevStartDate) && t.date.isBefore(prevEndDate),
        )
        .toList();

    // MEVCUT DÖNEM HESAPLAMALARI
    final incomeList = currentPeriodTransactions.where(
      (t) => t.type == TransactionType.income,
    );
    final expenseList = currentPeriodTransactions.where(
      (t) => t.type == TransactionType.expense,
    );

    totalIncome = incomeList.fold(0.0, (sum, t) => sum + t.amount);
    totalExpense = expenseList.fold(0.0, (sum, t) => sum + t.amount);
    netBalance = totalIncome - totalExpense;

    incomeSummary = incomeList.groupFoldBy(
      (t) => t.categoryId,
      (double? sum, t) => (sum ?? 0.0) + t.amount,
    );
    expenseSummary = expenseList.groupFoldBy(
      (t) => t.categoryId,
      (double? sum, t) => (sum ?? 0.0) + t.amount,
    );

    // KARŞILAŞTIRMA HESAPLAMALARI
    previousPeriodExpense = previousPeriodTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    if (previousPeriodExpense > 0) {
      expenseChangePercentage =
          ((totalExpense - previousPeriodExpense) / previousPeriodExpense);
    } else if (previousPeriodExpense == 0 && totalExpense > 0) {
      expenseChangePercentage = 1.0; // %100 artış (sonsuz yerine)
    } else {
      expenseChangePercentage = 0.0; // Değişim yok
    }
  }

  // ... (getTopExpenseData, getMonthlyTrendData, maxMonthlyValue metotlarında DEĞİŞİKLİK YOK) ...
  List<Map<String, dynamic>> getTopExpenseData({int count = 5}) {
    if (totalExpense == 0) return [];
    final sortedEntries = expenseSummary.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topItems = sortedEntries
        .take(count)
        .map(
          (e) => {
            'category': e.key,
            'amount': e.value,
            'percentage': totalExpense > 0 ? (e.value / totalExpense) : 0.0,
          },
        )
        .toList();

    final remainingAmount = sortedEntries
        .skip(count)
        .fold(0.0, (sum, e) => sum + e.value);

    if (remainingAmount > 0) {
      topItems.add({
        'category': 'Diğer',
        'amount': remainingAmount,
        'percentage': totalExpense > 0 ? (remainingAmount / totalExpense) : 0.0,
      });
    }
    return topItems;
  }

  List<Map<String, double>> getMonthlyTrendData() {
    final now = DateTime.now().toLocal();
    final data = <Map<String, double>>[];
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);
      final monthlyTransactions = _allTransactions.where(
        (t) =>
            t.date.isBefore(nextMonth) &&
            t.date.isAfter(month.subtract(const Duration(days: 1))),
      );
      final totalIncomeMonth = monthlyTransactions
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (sum, t) => sum + t.amount);
      final totalExpenseMonth = monthlyTransactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);
      data.add({
        'month': month.month.toDouble(),
        'income': totalIncomeMonth,
        'expense': totalExpenseMonth,
      });
    }
    return data;
  }

  double get maxMonthlyValue {
    double maxVal = 0.0;
    final trendData = getMonthlyTrendData();
    if (trendData.isEmpty) return 100.0; // Veri yoksa varsayılan bir değer
    for (var data in trendData) {
      if (data['income']! > maxVal) maxVal = data['income']!;
      if (data['expense']! > maxVal) maxVal = data['expense']!;
    }
    return maxVal == 0.0 ? 100.0 : maxVal * 1.1; // 0 olmasını engelle
  }
}
