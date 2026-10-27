import 'package:flutter/foundation.dart';
import 'dart:async';

import '../models/finance_model.dart';
import '../services/finance_service.dart';

enum ViewState { idle, loading, success, error }

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

  // 2. VERİ YÜKLEMESİ: tek istek, kendi sunucumuzdan
  bool _stale = false;
  String? _fxRateDate;

  /// Sunucu kaynaktan yeni veri alamadı; son alınan değerler gösteriliyor
  bool get isStale => _stale;

  /// ECB kurlarının tarihi (günde bir yayımlanır)
  String? get fxRateDate => _fxRateDate;

  Future<void> loadAllData() async {
    try {
      _setState(ViewState.loading);
      _errorMessage = '';
      final result = await _financeService.fetchMarkets();
      _financeData = result.items;
      _stale = result.stale;
      _fxRateDate = result.fxRateDate;
      _lastUpdateTime = _formatUpdateTime(result.updatedAt ?? DateTime.now());
      _setState(ViewState.success);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setState(ViewState.error);
    }
  }

  List<FinanceModel> getCurrencyData() =>
      _financeData.where((x) => x.category == MarketCategory.fx).toList();

  List<FinanceModel> getCryptoData() =>
      _financeData.where((x) => x.category == MarketCategory.crypto).toList();

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

  // Ekran kendi sıralamasını yapar (Önerilen/Değişim/Fiyat/İsim); burada isme göre
  List<FinanceModel> _sortData(List<FinanceModel> data) =>
      List.of(data)..sort((a, b) => a.name.compareTo(b.name));

  // 8. VALIDATION VE HELPER METODLARI
  bool get hasData => _financeData.isNotEmpty;
  bool get isLoading => _state == ViewState.loading;
  bool get hasError => _state == ViewState.error;
  bool get isEmpty => _financeData.isEmpty && !isLoading;

  String _formatUpdateTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
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


}
