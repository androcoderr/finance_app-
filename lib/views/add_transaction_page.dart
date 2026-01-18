// lib/views/add_transaction_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_borsa/views/widgets/home_widget/build_bottom_navigation_bar.dart';
// Gerekli Modeller ve Servisler
import '../models/category_model.dart';
import '../services/category_service.dart';
import '../view_model/user_view_model.dart';
import '../utils/error_handler.dart';
// Diğer ViewModel'ler
import 'package:test_borsa/view_model/home_view_model.dart';
import 'package:test_borsa/view_model/add_transaction_view_model.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage>
    with SingleTickerProviderStateMixin {
  // ⚠️ Sabit kodlanmış renkler kaldırıldı, Theme.of(context) kullanılacak.
  // final Color primaryBlue = const Color(0xFF2196F3);
  // final Color backgroundColor = const Color(0xFFF5F5F5);
  // final Color cardColor = Colors.white;
  // final Color textColor = const Color(0xFF333333);
  // final Color lightTextColor = const Color(0xFF666666);
  final Color greenColor = const Color(0xFF4CAF50); // Bu renkler değişmeyecek
  final Color redColor = const Color(0xFFF44336); // Bu renkler değişmeyecek

  late TabController _tabController;

  List<Category> allCategories = [];
  bool isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final loadedCategories = await CategoryService.getCategories();
      setState(() {
        allCategories = loadedCategories;
        isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        isLoadingCategories = false;
      });
      // Renk sabit tutuldu
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      Provider.of<AddTransactionViewModel>(
        context,
        listen: false,
      ).setSelectedTabIndex(_tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Category> _getFilteredCategories(bool isExpense) {
    final bool isIncome = !isExpense;
    // Kategori modelinde isExpense yerine isIncome kullanıldığını varsayarak filtrelendi.
    return allCategories.where((cat) => cat.isIncome == isIncome).toList();
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.trim()) {
      case "Maaş":
      case "Prim":
      case "Ek Gelir":
        return Icons.account_balance_wallet;
      case "Hediye":
        return Icons.card_giftcard;
      case "Yatırım":
        return Icons.show_chart;
      case "Faiz":
        return Icons.percent;
      case "Market":
      case "Alışveriş":
        return Icons.shopping_cart;
      case "Yiyecek":
      case "Atıştırmalık":
        return Icons.restaurant;
      case "Telefon":
      case "Elektronik":
        return Icons.phone_android;
      case "Eğlence":
      case "Oyun":
      case "Sosyal":
        return Icons.movie;
      case "Eğitim":
        return Icons.school;
      case "Güzellik":
        return Icons.face_retouching_natural;
      case "Spor":
        return Icons.fitness_center;
      case "Ulaşım":
      case "Araba":
        return Icons.directions_car;
      case "Giyim":
        return Icons.checkroom;
      case "İçecekler":
      case "Sigara":
        return Icons.local_bar;
      case "Seyahat":
        return Icons.flight;
      case "Sağlık":
        return Icons.local_hospital;
      case "Pet":
        return Icons.pets;
      case "Onarım":
        return Icons.build;
      case "Konut":
        return Icons.home;
      case "Mobilya":
        return Icons.weekend;
      case "Bağış":
        return Icons.volunteer_activism;
      case "Çocuk":
        return Icons.child_care;
      case "Hediyeler":
        return Icons.card_giftcard;
      case "Diğer":
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tema renklerini al
    final Color primaryBlue = Theme.of(context).colorScheme.primary;
    final Color backgroundColor = Theme.of(context).colorScheme.surface;
    final Color cardColor = Theme.of(
      context,
    ).cardColor; // Kart/Yüzey rengi için cardColor veya surface kullanılabilir
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    final Color lightTextColor = Theme.of(
      context,
    ).colorScheme.onSurface.withOpacity(0.6);

    return Consumer2<HomeViewModel, AddTransactionViewModel>(
      builder: (context, homeViewModel, transactionViewModel, child) {
        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: primaryBlue,
            elevation: 0,
            title: Text(
              'İşlem Ekle',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            // Geri tuşu rengi, AppBar arka planı primary olduğu için beyaz tutuldu
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          bottomNavigationBar: buildBottomNavigationBar(context, homeViewModel),
          body: Stack(
            children: [
              Column(
                children: [
                  // Custom Tab Bar
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: primaryBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor:
                          Colors.white, // Seçili tab yazısı beyaz olmalı
                      unselectedLabelColor: lightTextColor,
                      labelStyle: TextStyle(fontWeight: FontWeight.w600),
                      unselectedLabelStyle: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.remove_circle_outline, size: 18),
                              SizedBox(width: 8),
                              Text('Gider'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline, size: 18),
                              SizedBox(width: 8),
                              Text('Gelir'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab Bar View
                  Expanded(
                    child: isLoadingCategories
                        ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primaryBlue,
                              ),
                            ),
                          )
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildCategoryGrid(
                                _getFilteredCategories(true),
                                transactionViewModel,
                                primaryBlue: primaryBlue,
                                cardColor: cardColor,
                                backgroundColor: backgroundColor,
                                textColor: textColor,
                                lightTextColor: lightTextColor,
                                isExpense: true,
                              ),
                              _buildCategoryGrid(
                                _getFilteredCategories(false),
                                transactionViewModel,
                                primaryBlue: primaryBlue,
                                cardColor: cardColor,
                                backgroundColor: backgroundColor,
                                textColor: textColor,
                                lightTextColor: lightTextColor,
                                isExpense: false,
                              ),
                            ],
                          ),
                  ),
                ],
              ),
              // Loading overlay
              if (transactionViewModel.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryGrid(
    List<Category> kategoriler,
    AddTransactionViewModel viewModel, {
    required bool isExpense,
    required Color primaryBlue, // Tema renkleri artık parametre olarak alınıyor
    required Color cardColor,
    required Color backgroundColor,
    required Color textColor,
    required Color lightTextColor,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isExpense ? 'Gider Kategorisi Seçin' : 'Gelir Kategorisi Seçin',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: kategoriler.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final kategori = kategoriler[index];
              final isSelected = viewModel.selectedCategory == kategori.id;

              return GestureDetector(
                onTap: () {
                  viewModel.setSelectedCategory(
                    isSelected ? null : kategori.id,
                  );
                  if (!isSelected) {
                    _showAmountDialog(viewModel, kategori);
                  }
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? primaryBlue : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? primaryBlue.withOpacity(0.2)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: isSelected ? 8 : 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryBlue.withOpacity(0.1)
                              : Theme.of(context)
                                    .colorScheme
                                    .surface, // Background yerine surface kullanıldı
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getCategoryIcon(kategori.name),
                          color: isSelected ? primaryBlue : lightTextColor,
                          size: 24,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        kategori.name,
                        style: TextStyle(
                          color: isSelected ? primaryBlue : textColor,
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // ✅ Güvenli Hale Getirilmiş Dialog Metodu
  void _showAmountDialog(AddTransactionViewModel viewModel, Category category) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();

    // Tema renklerini dialog içinde kullanmak için tekrar al
    final Color primaryBlue = Theme.of(context).colorScheme.primary;
    final Color cardColor = Theme.of(context).cardColor;
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    final Color lightTextColor = Theme.of(
      context,
    ).colorScheme.onSurface.withOpacity(0.6);

    // Sayfa context'ini yakalama (Asenkron işlem sonrası kullanım için)
    final pageContext = context;

    showModalBottomSheet(
      context: pageContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ), // SurfaceVariant kullanıldı
              Text(
                'İşlem Detayları',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              // Selected category display
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(_getCategoryIcon(category.name), color: primaryBlue),
                    SizedBox(width: 12),
                    Text(
                      category.name,
                      style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              // Amount input
              TextField(
                controller: amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  labelText: 'Tutar',
                  prefixText: '₺ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryBlue, width: 2),
                  ),
                  labelStyle: TextStyle(color: lightTextColor),
                  prefixStyle: TextStyle(color: textColor),
                ),
              ),
              SizedBox(height: 16),
              // Note input
              TextField(
                controller: noteController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Not (İsteğe bağlı)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryBlue, width: 2),
                  ),
                  labelStyle: TextStyle(color: lightTextColor),
                ),
              ),
              SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        viewModel.setSelectedCategory(null);
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ), // outlineVariant kullanıldı
                      ),
                      child: Text(
                        'İptal',
                        style: TextStyle(
                          color: lightTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        // 1. VALIDASYONLAR
                        if (amountController.text.isEmpty) {
                          // SnackBar için context: Dialog context'i kullanılıyor
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lütfen tutar giriniz'),
                              backgroundColor: redColor,
                            ),
                          );
                          return;
                        }

                        final amount = double.tryParse(amountController.text);
                        if (amount == null || amount <= 0) {
                          // SnackBar için context: Dialog context'i kullanılıyor
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lütfen geçerli bir tutar giriniz'),
                              backgroundColor: redColor,
                            ),
                          );
                          return;
                        }

                        // 2. DİALOG'U KAPAT
                        Navigator.pop(context);

                        // 3. İŞLEMİ YAP
                        // pageContext (ana sayfa context'i) kullanılıyor.
                        final userViewModel = Provider.of<UserViewModel>(
                          pageContext,
                          listen: false,
                        );
                        final String? userId = userViewModel.currentUser?.id;

                        if (userId == null) {
                          if (pageContext.mounted) {
                            ScaffoldMessenger.of(pageContext).showSnackBar(
                              SnackBar(
                                content: Text('Kullanıcı bilgisi bulunamadı.'),
                                backgroundColor: redColor,
                              ),
                            );
                          }
                          return;
                        }

                        final success = await viewModel.addTransaction(
                          userId: userId,
                          amount: amount,
                          categoryId: category.id,
                          description: noteController.text.trim(),
                        );

                        // 4. SONUÇLARI GÖSTER (mounted kontrolü ile güvenli)
                        if (!pageContext.mounted)
                          return; // ⚠️ Güvenlik Kontrolü

                        if (success) {
                          final homeViewModel = Provider.of<HomeViewModel>(
                            pageContext,
                            listen: false,
                          );
                          await homeViewModel.refresh();

                          ScaffoldMessenger.of(pageContext).showSnackBar(
                            SnackBar(
                              content: Text('İşlem başarıyla kaydedildi'),
                              backgroundColor: greenColor,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(pageContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                'İşlem kaydedilemedi. Lütfen tekrar deneyin.',
                              ),
                              backgroundColor: redColor,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Kaydet',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
