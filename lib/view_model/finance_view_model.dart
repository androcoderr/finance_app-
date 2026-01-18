import 'package:flutter/foundation.dart';
import 'dart:async';

import '../models/finance_model.dart';
import '../services/finance_service.dart';

enum ViewState { idle, loading, success, error }

enum SortType { name, price, change, date }

class FinanceViewModel extends ChangeNotifier {
  final FinanceService _financeService;

  // State Management
  ViewState _state = ViewState.idle;
  ViewState get state => _state;

  // Data
  List<FinanceModel> _financeData = [];
  List<FinanceModel> get financeData => _financeData;

  // Error Handling
  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // UI State
  String _lastUpdateTime = '';
  String get lastUpdateTime => _lastUpdateTime;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  // Filtering & Sorting
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  SortType _currentSortType = SortType.name;
  bool _isAscending = true;

  List<FinanceModel> get filteredData {
    List<FinanceModel> filtered = _financeData;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (item) =>
                item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                item.currency.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    // Sort
    filtered = _sortData(filtered);

    return filtered;
  }

  FinanceViewModel(this._financeService);

  // ================ VIEWMODEL'İN TEMEL İŞLEVLERİ ================

  // 1. STATE YÖNETİMİ
  void _setState(ViewState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  // 2. VERİ YÜKLEMESİ - Geliştirilmiş
  Future<void> loadAllData() async {
    try {
      _setState(ViewState.loading);
      _errorMessage = '';

      // Paralel veri yükleme
      final results = await Future.wait([
        _financeService.fetchExchangeRates().catchError((e) {
          print('Döviz verisi hatası: $e');
          return <FinanceModel>[];
        }),
        _financeService.fetchBISTData().catchError((e) {
          print('BIST verisi hatası: $e');
          return <FinanceModel>[];
        }),
        _financeService.fetchTurkishGoldData().catchError((e) {
          print('Altın verisi hatası: $e');
          return <FinanceModel>[];
        }),
        _financeService.fetchCryptoData().catchError((e) {
          print('Kripto verisi hatası: $e');
          return <FinanceModel>[];
        }),
      ]);

      // Verileri birleştir
      _financeData = [
        ...results[0], // Dövizler
        ...results[1], // BIST
        ...results[2], // Altın (TL)
        ...results[3], // Kripto
      ];

      if (_financeData.isEmpty) {
        throw Exception('Hiçbir veri alınamadı');
      }

      _lastUpdateTime = _formatUpdateTime(DateTime.now());
      _setState(ViewState.success);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ViewState.error);
      debugPrint('loadAllData hatası: $e');
    }
  }

  // Belirli kategorilere göre veri alma
  List<FinanceModel> getCurrencyData() {
    return _financeData
        .where(
          (item) =>
              item.name.contains('USD') ||
              item.name.contains('EUR') ||
              item.name.contains('GBP') ||
              item.name.contains('TRY'),
        )
        .toList();
  }

  List<FinanceModel> getTurkishGoldData() {
    return _financeData
        .where(
          (item) =>
              item.currency == '₺' &&
              (item.name.contains('Altın') ||
                  item.name.contains('Çeyrek') ||
                  item.name.contains('Yarım') ||
                  item.name.contains('Tam') ||
                  item.name.contains('Ayar') ||
                  item.name.contains('Gremse')),
        )
        .toList();
  }

  List<FinanceModel> getInternationalGoldData() {
    return _financeData
        .where(
          (item) =>
              item.currency == '\$' &&
              (item.name.contains('Gold') || item.name.contains('Silver')),
        )
        .toList();
  }

  List<FinanceModel> getCryptoData() {
    return _financeData
        .where(
          (item) =>
              item.name.contains('Bitcoin') ||
              item.name.contains('Ethereum') ||
              item.name.contains('Cardano') ||
              item.name.contains('Binance') ||
              item.symbol == '₿' ||
              item.symbol == 'Ξ' ||
              item.symbol == '₳',
        )
        .toList();
  }

  List<FinanceModel> getBISTData() {
    return _financeData
        .where(
          (item) =>
              item.name.contains('BIST') ||
              item.symbol == '📊' ||
              item.symbol == '📈',
        )
        .toList();
  }

  // 3. YENİLEME İŞLEMİ - Geliştirilmiş
  Future<void> refreshData() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    notifyListeners();

    try {
      await loadAllData();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // 4. ARAMA İŞLEMİ
  void updateSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  void clearSearch() {
    updateSearchQuery('');
  }

  // 5. SIRALAMA İŞLEMLERİ - Geliştirilmiş
  void sortBy(SortType sortType) {
    if (_currentSortType == sortType) {
      _isAscending = !_isAscending;
    } else {
      _currentSortType = sortType;
      _isAscending = true;
    }
    notifyListeners();
  }

  List<FinanceModel> _sortData(List<FinanceModel> data) {
    List<FinanceModel> sortedData = List.from(data);

    switch (_currentSortType) {
      case SortType.name:
        sortedData.sort(
          (a, b) => _isAscending
              ? a.name.compareTo(b.name)
              : b.name.compareTo(a.name),
        );
        break;
      case SortType.price:
        sortedData.sort(
          (a, b) => _isAscending
              ? a.price.compareTo(b.price)
              : b.price.compareTo(a.price),
        );
        break;
      case SortType.change:
        sortedData.sort(
          (a, b) => _isAscending
              ? a.change.compareTo(b.change)
              : b.change.compareTo(a.change),
        );
        break;
      case SortType.date:
        sortedData.sort(
          (a, b) => _isAscending
              ? a.lastUpdate.compareTo(b.lastUpdate)
              : b.lastUpdate.compareTo(a.lastUpdate),
        );
        break;
    }

    return sortedData;
  }

  // Getter for current sort info
  SortType get currentSortType => _currentSortType;
  bool get isAscending => _isAscending;

  // 6. FİLTRELEME - Geliştirilmiş
  List<FinanceModel> getPositiveChanges() {
    return _financeData.where((item) => item.change > 0).toList();
  }

  List<FinanceModel> getNegativeChanges() {
    return _financeData.where((item) => item.change < 0).toList();
  }

  List<FinanceModel> getTopGainers({int limit = 5}) {
    var sorted = List<FinanceModel>.from(_financeData);
    sorted.sort((a, b) => b.change.compareTo(a.change));
    return sorted.take(limit).toList();
  }

  List<FinanceModel> getTopLosers({int limit = 5}) {
    var sorted = List<FinanceModel>.from(_financeData);
    sorted.sort((a, b) => a.change.compareTo(b.change));
    return sorted.take(limit).toList();
  }

  // 7. İSTATİSTİK HESAPLAMALARI - Geliştirilmiş
  double get totalPositiveChange {
    return _financeData
        .where((item) => item.change > 0)
        .fold(0.0, (sum, item) => sum + item.change);
  }

  double get totalNegativeChange {
    return _financeData
        .where((item) => item.change < 0)
        .fold(0.0, (sum, item) => sum + item.change);
  }

  double get averageChange {
    if (_financeData.isEmpty) return 0.0;
    double total = _financeData.fold(0.0, (sum, item) => sum + item.change);
    return total / _financeData.length;
  }

  int get positiveCount {
    return _financeData.where((item) => item.change > 0).length;
  }

  int get negativeCount {
    return _financeData.where((item) => item.change < 0).length;
  }

  int get neutralCount {
    return _financeData.where((item) => item.change == 0).length;
  }

  // 8. VALIDATION VE HELPER METODLARI
  bool get hasData => _financeData.isNotEmpty;
  bool get isLoading => _state == ViewState.loading;
  bool get hasError => _state == ViewState.error;
  bool get isSuccess => _state == ViewState.success;
  bool get isEmpty => _financeData.isEmpty && !isLoading;

  String _formatUpdateTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }

  // 9. HATA YÖNETİMİ
  void clearError() {
    if (_errorMessage.isNotEmpty) {
      _errorMessage = '';
      notifyListeners();
    }
  }

  Future<void> retryLastOperation() async {
    clearError();
    await loadAllData();
  }

  // 10. FAVORILER YÖNETİMİ - Geliştirilmiş
  final Set<String> _favorites = <String>{};
  Set<String> get favorites => Set.unmodifiable(_favorites);

  void toggleFavorite(String itemName) {
    if (_favorites.contains(itemName)) {
      _favorites.remove(itemName);
    } else {
      _favorites.add(itemName);
    }
    notifyListeners();
  }

  bool isFavorite(String itemName) {
    return _favorites.contains(itemName);
  }

  List<FinanceModel> get favoriteItems {
    return _financeData
        .where((item) => _favorites.contains(item.name))
        .toList();
  }

  void clearFavorites() {
    if (_favorites.isNotEmpty) {
      _favorites.clear();
      notifyListeners();
    }
  }

  // 11. CACHE YÖNETİMİ - Geliştirilmiş
  DateTime? _lastFetchTime;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  bool get shouldRefreshCache {
    if (_lastFetchTime == null) return true;
    return DateTime.now().difference(_lastFetchTime!) > _cacheTimeout;
  }

  Future<void> loadDataWithCache() async {
    if (!shouldRefreshCache && hasData) {
      return; // Cache'den kullan
    }

    await loadAllData();
    _lastFetchTime = DateTime.now();
  }

  // Cache temizleme
  void clearCache() {
    _lastFetchTime = null;
    _financeData.clear();
    _setState(ViewState.idle);
  }

  // 12. OTOMATİK YENİLEME
  Timer? _autoRefreshTimer;
  bool _autoRefreshEnabled = false;

  bool get autoRefreshEnabled => _autoRefreshEnabled;

  void enableAutoRefresh({Duration interval = const Duration(minutes: 2)}) {
    _autoRefreshEnabled = true;
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(interval, (_) {
      if (!_isRefreshing && _state != ViewState.loading) {
        refreshData();
      }
    });
    notifyListeners();
  }

  void disableAutoRefresh() {
    _autoRefreshEnabled = false;
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    notifyListeners();
  }

  // 13. CLEANUP - Geliştirilmiş
  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _financeService.dispose();
    super.dispose();
  }

  // 14. DEBUG HELPER METHODS
  void printDebugInfo() {
    debugPrint('=== FinanceViewModel Debug Info ===');
    debugPrint('State: $_state');
    debugPrint('Data count: ${_financeData.length}');
    debugPrint('Favorites count: ${_favorites.length}');
    debugPrint('Last update: $_lastUpdateTime');
    debugPrint('Auto refresh: $_autoRefreshEnabled');
    debugPrint('Search query: "$_searchQuery"');
    debugPrint('Sort: $_currentSortType (${_isAscending ? "ASC" : "DESC"})');
    debugPrint('====================================');
  }
}
