import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_borsa/models/recurring_transaction_model.dart';
import 'package:test_borsa/services/recurring_transaction_service.dart';
import 'package:test_borsa/services/transaction_service.dart';
import 'package:test_borsa/services/category_service.dart';
import 'package:test_borsa/view_model/user_view_model.dart';

// Modeller
import '../models/asset_model.dart';
import '../models/budget_analysis.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/chart_data.dart';
import '../models/goal_analysis.dart';
import '../models/goal_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';

class HomeViewModel extends ChangeNotifier {
  bool _secretMoney = false;
  bool get secretMoney => _secretMoney;

  Future<void> loadSecretMoneyPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _secretMoney = prefs.getBool('budget-hide') ?? false;
    notifyListeners();
  }

  Future<void> setSecretMoney(bool value) async {
    _secretMoney = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('budget-hide', value);
    notifyListeners();
  }

  final UserViewModel _userViewModel;
  final TransactionService _transactionService = TransactionService();
  final RecurringTransactionService _recurringTransactionService =
      RecurringTransactionService();
  final CategoryService _categoryService = CategoryService();

  // Dispose kontrolü için flag
  bool _disposed = false;

  // Senkron UI verileri
  double totalIncomeThisMonthPublic = 0.0;
  double totalExpenseThisMonthPublic = 0.0;
  List<Asset> _assets = [];
  List<TransactionModel> _recentTransactions = [];
  List<ChartData> _incomeData = [];
  List<ChartData> _expenseData = [];
  List<Category> _categories = [];
  // GÜNCELLEME: Tüm işlemleri ViewModel içinde tutmak için yeni bir liste
  List<TransactionModel> _allTransactions = [];

  // Getter'lar
  List<Asset> get assets => _assets;
  List<TransactionModel> get recentTransactions => _recentTransactions;
  List<TransactionModel> get recentTransactionsLimited =>
      _recentTransactions.take(5).toList();
  List<ChartData> get incomeData => _incomeData;
  List<ChartData> get expenseData => _expenseData;
  List<Category> get categories => _categories;

  // GÜNCELLEME: Token'a erişmek için bir yardımcı getter eklendi.
  // (UserViewModel'inizin 'accessToken' adında bir getter'ı olduğunu varsayıyoruz)
  String? get _accessToken => _userViewModel.authToken;

  // Kategori stilleri
  final Map<String, Color> _categoryColors = {};
  final Map<String, IconData> _categoryIcons = {};

  HomeViewModel(this._userViewModel) {
    _userViewModel.addListener(_onUserChanged);
    _loadData();
    loadSecretMoneyPreference();
  }

  @override
  void dispose() {
    _disposed = true;
    _userViewModel.removeListener(_onUserChanged);
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  void _onUserChanged() {
    if (!_disposed) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_disposed) return;

    // GÜNCELLEME: Token'ı en başta kontrol et
    final token = _accessToken;
    if (currentUser == null || token == null) {
      print(
        'HomeViewModel: Kullanıcı veya Token bulunamadı. Veri yükleme durduruldu.',
      );
      _resetData();
      if (!_disposed) notifyListeners();
      return;
    }

    try {
      // Önce kategorileri yükle (loglarınıza göre bu public, token gerekmiyor)
      await _loadCategories();

      // Sonra (kategoriler hazır olunca) işlemleri token ile yükle
      await _loadTransactionsAndCalculate(token);

      if (!_disposed) notifyListeners();
    } catch (e) {
      if (_disposed) return;
      _resetData();
      if (!_disposed) notifyListeners();
      print('HomeViewModel _loadData error: $e');
    }
  }

  Future<void> _loadCategories() async {
    // BU METOTTA DEĞİŞİKLİK YOK
    // Loglarınıza göre /categories 200 OK dönüyor (token gerekmiyor)
    try {
      _categories = await CategoryService.getCategories();
      _initializeCategoryStyles();
    } catch (e) {
      print('Kategori yükleme hatası: $e');
      _categories = [];
    }
  }

  // GÜNCELLEME: Bu metot artık 'accessToken' parametresi alıyor
  Future<void> _loadTransactionsAndCalculate(String accessToken) async {
    // currentUser!.id yerine daha güvenli olan userId getter'ını kullan
    if (userId == null) return;

    // 1. Normal İşlemleri Getir
    try {
      _allTransactions = await _transactionService.getTransactions(
        userId!,
        accessToken,
      );
    } catch (e) {
      print('İşlemler yüklenirken hata oluştu: $e');
      _allTransactions = [];
    }

    // 2. Tekrarlayan İşlemleri Getir
    double recurringNetEffect = 0;
    try {
      final List<RecurringTransaction> allRecurring =
          await RecurringTransactionService.getRecurringTransactions();
      // Tekrarlayan işlemlerin net etkisini hesapla
      recurringNetEffect = _calculateRecurringTotal(allRecurring);
    } catch (e) {
      print('Tekrarlayan işlemler yüklenirken hata oluştu: $e');
      // Tekrarlayan işlemler gelmezse 0 olarak kabul et ve devam et
    }

    if (_disposed) return;

    double incomeThisMonth = calculateIncomeThisMonth(_allTransactions);
    double expenseThisMonth = calculateExpenseThisMonth(_allTransactions);

    totalIncomeThisMonthPublic = incomeThisMonth;
    totalExpenseThisMonthPublic = expenseThisMonth;

    final totalIncomeAll = _allTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpenseAll = _allTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    // Net Bakiye Hesabı: Normal İşlemler + Tekrarlayan İşlemlerin Kümülatif Etkisi
    final netAmount = totalIncomeAll - totalExpenseAll + recurringNetEffect;

    _assets = [
      Asset(name: 'Toplam Bakiye', amount: netAmount, currency: 'TL'),
      Asset(name: 'Bu Ay Gelir', amount: incomeThisMonth, currency: 'TL'),
      Asset(name: 'Bu Ay Gider', amount: expenseThisMonth, currency: 'TL'),
    ];

    final now = DateTime.now();
    _recentTransactions =
        _allTransactions
            .where((t) => t.date.isAfter(now.subtract(Duration(days: 30))))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    _incomeData = _calculateChartData(_allTransactions, TransactionType.income);
    _expenseData = _calculateChartData(
      _allTransactions,
      TransactionType.expense,
    );
  }

  // --- Tekrarlayan İşlem Hesaplamaları ---
  double _calculateRecurringTotal(List<RecurringTransaction> transactions) {
    final now = DateTime.now();
    double total = 0;

    for (var transaction in transactions) {
      if (transaction.endDate != null && transaction.endDate!.isBefore(now)) {
        continue;
      }

      final daysSinceStart = now.difference(transaction.startDate).inDays;
      if (daysSinceStart < 0) continue;

      int occurrenceCount = 0;

      switch (transaction.frequency) {
        case 'daily':
          occurrenceCount = daysSinceStart + 1;
          break;
        case 'weekly':
          occurrenceCount = (daysSinceStart / 7).floor() + 1;
          break;
        case 'monthly':
          occurrenceCount = _monthsBetween(transaction.startDate, now) + 1;
          break;
        case 'yearly':
          occurrenceCount = now.year - transaction.startDate.year + 1;
          break;
      }

      if (transaction.endDate != null) {
        final maxOccurrences = _calculateMaxOccurrences(
          transaction.startDate,
          transaction.endDate!,
          transaction.frequency,
        );
        occurrenceCount = occurrenceCount > maxOccurrences
            ? maxOccurrences
            : occurrenceCount;
      }

      final totalAmount = transaction.amount * occurrenceCount;
      if (transaction.type == 'income') {
        total += totalAmount;
      } else {
        total -= totalAmount;
      }
    }

    return total;
  }

  int _monthsBetween(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + end.month - start.month;
  }

  int _calculateMaxOccurrences(DateTime start, DateTime end, String frequency) {
    final daysBetween = end.difference(start).inDays;

    switch (frequency) {
      case 'daily':
        return daysBetween + 1;
      case 'weekly':
        return (daysBetween / 7).floor() + 1;
      case 'monthly':
        return _monthsBetween(start, end) + 1;
      case 'yearly':
        return end.year - start.year + 1;
      default:
        return 0;
    }
  }

  void _initializeCategoryStyles() {
    _categoryColors.clear();
    _categoryIcons.clear();

    // Önceden tanımlı stiller
    final predefinedStyles = {
      'Market': {'color': Colors.red, 'icon': Icons.shopping_cart},
      'Alışveriş': {'color': Colors.purple, 'icon': Icons.shopping_bag},
      'Yiyecek': {'color': Colors.orange, 'icon': Icons.restaurant},
      'Telefon': {'color': Colors.blue, 'icon': Icons.phone},
      'Eğlence': {'color': Colors.green, 'icon': Icons.movie},
      'Eğitim': {'color': Colors.indigo, 'icon': Icons.school},
      'Güzellik': {'color': Colors.pink, 'icon': Icons.spa},
      'Spor': {'color': Colors.teal, 'icon': Icons.fitness_center},
      'Sosyal': {'color': Colors.cyan, 'icon': Icons.people},
      'Ulaşım': {'color': Colors.blue, 'icon': Icons.directions_car},
      'Giyim': {'color': Colors.purple, 'icon': Icons.checkroom},
      'Araba': {'color': Colors.blueGrey, 'icon': Icons.directions_car},
      'İçecekler': {'color': Colors.brown, 'icon': Icons.local_drink},
      'Sigara': {'color': Colors.grey, 'icon': Icons.smoking_rooms},
      'Elektronik': {'color': Colors.deepPurple, 'icon': Icons.computer},
      'Seyahat': {'color': Colors.lightBlue, 'icon': Icons.flight},
      'Sağlık': {'color': Colors.pink, 'icon': Icons.local_hospital},
      'Pet': {'color': Colors.amber, 'icon': Icons.pets},
      'Onarım': {'color': Colors.orange, 'icon': Icons.build},
      'Konut': {'color': Colors.brown, 'icon': Icons.home},
      'Mobilya': {'color': Colors.deepOrange, 'icon': Icons.chair},
      'Hediyeler': {'color': Colors.red, 'icon': Icons.card_giftcard},
      'Bağış': {'color': Colors.green, 'icon': Icons.volunteer_activism},
      'Oyun': {'color': Colors.purple, 'icon': Icons.videogame_asset},
      'Atıştırmalık': {'color': Colors.orange, 'icon': Icons.fastfood},
      'Çocuk': {'color': Colors.pink, 'icon': Icons.child_care},
      'Diğer': {'color': Colors.grey, 'icon': Icons.category},
      'Maaş': {'color': Colors.green, 'icon': Icons.work},
      'Prim': {'color': Colors.lightGreen, 'icon': Icons.attach_money},
      'Hediye': {'color': Colors.red, 'icon': Icons.card_giftcard},
      'Yatırım': {'color': Colors.teal, 'icon': Icons.trending_up},
      'Ek Gelir': {'color': Colors.cyan, 'icon': Icons.money},
      'Faiz': {'color': Colors.green, 'icon': Icons.account_balance},
      'Diğer Gelir': {'color': Colors.grey, 'icon': Icons.payments},
    };

    for (final category in _categories) {
      final style = predefinedStyles[category.name];
      _categoryColors[category.id] =
          style?['color'] as Color? ?? _getRandomColor(category.id);
      _categoryIcons[category.id] =
          style?['icon'] as IconData? ?? Icons.category;
    }
  }

  Color _getRandomColor(String seed) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
      Colors.deepOrange,
      Colors.lightBlue,
    ];
    final index = seed.hashCode % colors.length;
    return colors[index];
  }

  void _resetData() {
    totalIncomeThisMonthPublic = 0.0;
    totalExpenseThisMonthPublic = 0.0;
    _assets = [];
    _recentTransactions = [];
    _incomeData = [];
    _expenseData = [];
    _categories = [];
    _allTransactions = []; // GÜNCELLEME: Bunu da sıfırla
  }

  List<ChartData> _calculateChartData(
    List<TransactionModel> transactions,
    TransactionType type,
  ) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final Map<String, double> categoryTotals = {};
    for (final t in transactions) {
      if (t.type == type && !t.date.isBefore(startOfMonth)) {
        categoryTotals[t.categoryId] =
            (categoryTotals[t.categoryId] ?? 0.0) + t.amount;
      }
    }

    final List<ChartData> list = categoryTotals.entries.map((e) {
      final cat = getCategoryById(e.key);
      return ChartData(
        categoryId: e.key,
        categoryName: cat?.name ?? 'Bilinmeyen',
        amount: e.value,
        color: getCategoryColor(e.key),
      );
    }).toList();

    list.sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  // --- Public Getter'lar ---
  User? get currentUser => _userViewModel.currentUser;
  String? get userId => _userViewModel.userId;
  List<Budget> get budgets => currentUser?.budgets ?? [];
  List<Goal> get goals => currentUser?.goals ?? [];
  List<Object> get recurringTransactions =>
      currentUser?.recurringTransactions ?? [];

  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      //print('Kategori bulunamadı: $id');
      //print('Mevcut kategoriler: ${_categories.map((c) => '${c.id}: ${c.name}').toList()}');
      return null;
    }
  }

  Color getCategoryColor(String categoryId) =>
      _categoryColors[categoryId] ?? Colors.grey;
  IconData getCategoryIcon(String categoryId) =>
      _categoryIcons[categoryId] ?? Icons.category;

  // --- Hesaplamalar (UI için gerekirse) ---
  double calculateIncomeThisMonth(List<TransactionModel> transactions) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return transactions
        .where(
          (t) =>
              t.type == TransactionType.income &&
              !t.date.isBefore(startOfMonth),
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double calculateExpenseThisMonth(List<TransactionModel> transactions) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return transactions
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              !t.date.isBefore(startOfMonth),
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // --- Navigation ---
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;
  void onBottomNavTap(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  // --- İşlem ekleme ---
  Future<void> addTransaction(TransactionModel transaction) async {
    if (_disposed || currentUser == null) return;

    // GÜNCELLEME: Token'ı al ve kontrol et
    final token = _accessToken;
    if (token == null) {
      print('HomeViewModel Error: Token yok, işlem eklenemiyor.');
      return;
    }

    // GÜNCELLEME: Servis çağrısına token'ı ekle
    await _transactionService.addTransaction(transaction, token);
    await _loadData(); // Yeniden yükle
  }

  // --- Hedef güncelleme ---
  Future<void> updateGoalProgress(String goalId, double amount) async {
    if (_disposed || currentUser == null) return;

    // Bu metot _userViewModel'i güncelliyor, _transactionService'i değil.
    // _userViewModel kendi token yönetimini yapmalıdır.
    final updatedGoals = currentUser!.goals.map((goal) {
      if (goal.id == goalId) {
        return Goal(
          id: goal.id,
          userId: goal.userId,
          name: goal.name,
          targetAmount: goal.targetAmount,
          currentAmount: goal.currentAmount + amount,
          createdAt: goal.createdAt,
          targetDate: goal.targetDate,
        );
      }
      return goal;
    }).toList();

    final updatedUser = currentUser!.copyWith(goals: updatedGoals);
    await _userViewModel.updateUser(updatedUser);
  }

  // --- Bütçe analizi ---
  List<BudgetAnalysis> get budgetAnalyses {
    if (currentUser == null) return [];
    return budgets.map((budget) {
      final spent = getCurrentSpentForBudget(budget);
      final percentage = budget.limitAmount > 0
          ? (spent / budget.limitAmount) * 100.0
          : 0.0;
      return BudgetAnalysis(
        budget: budget,
        spentAmount: spent,
        remainingAmount: budget.limitAmount - spent,
        percentage: percentage,
        isOverBudget: spent > budget.limitAmount,
      );
    }).toList();
  }

  Future<void> refresh() async {
    if (_disposed) return;
    await _loadData();
  }

  double getCurrentSpentForBudget(Budget budget) {
    if (currentUser == null) return 0.0;

    // GÜNCELLEME: Hata düzeltmesi.
    // Stale (bayat) olabilecek 'currentUser!.transactions' yerine,
    // bu ViewModel'in kendi tuttuğu '_allTransactions' listesini kullan.
    return _allTransactions
        .where(
          (t) =>
              t.categoryId == budget.categoryId &&
              t.type == TransactionType.expense &&
              !t.date.isBefore(budget.startDate) &&
              !t.date.isAfter(budget.endDate),
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // --- Hedef analizi ---
  List<GoalAnalysis> get goalAnalyses {
    return goals.map((goal) {
      final progress = goal.targetAmount > 0
          ? (goal.currentAmount / goal.targetAmount) * 100.0
          : 0.0;
      final remaining = goal.targetAmount - goal.currentAmount;
      int? remainingDays;
      if (goal.targetDate != null) {
        remainingDays = goal.targetDate!.difference(DateTime.now()).inDays;
      }
      return GoalAnalysis(
        goal: goal,
        progress: progress,
        remainingAmount: remaining,
        remainingDays: remainingDays,
        isCompleted: goal.currentAmount >= goal.targetAmount,
      );
    }).toList();
  }

  // --- Yardımcı metodlar ---
  String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) return 'Bugün';
    if (difference.inDays == 1) return 'Dün';
    return '${date.day} ${_getMonthName(date.month)}';
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];
    return months[month];
  }

  String formatCurrency(double amount) => '₺${amount.toStringAsFixed(2)}';

  bool get hasUser => currentUser != null;
  bool get hasTransactions => _recentTransactions.isNotEmpty;
  bool get hasGoals => goals.isNotEmpty;
  bool get hasBudgets => budgets.isNotEmpty;

  String get userGreeting {
    if (currentUser == null) return 'Merhaba!';
    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12
        ? 'Günaydın'
        : (hour < 18 ? 'İyi günler' : 'İyi akşamlar');
    return '$timeGreeting, ${currentUser!.name}!';
  }
}