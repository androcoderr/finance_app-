import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bill_model.dart';
import '../view_model/bill_view_model.dart';
import '../view_model/user_view_model.dart';

class BillsPage extends StatefulWidget {
  const BillsPage({super.key});

  @override
  _BillsPageState createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialLoad) {
      final token = context.read<UserViewModel>().authToken;
      if (token != null) {
        // HATA DÜZELTME: Build sırasında state güncellemesini önlemek için microtask kullanıyoruz
        Future.microtask(() => context.read<BillsViewModel>().fetchBills(token));
        _isInitialLoad = false;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userViewModel = context.watch<UserViewModel>();
    final token = userViewModel.authToken;

    if (token == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Faturalarım')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade400),
              SizedBox(height: 16),
              Text(
                'Faturaları görmek için lütfen giriş yapın.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    final billsViewModel = context.watch<BillsViewModel>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('Faturalarım'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: billsViewModel.isLoading
                ? null
                : () => context.read<BillsViewModel>().fetchBills(token),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Container(
            color: Theme.of(context).appBarTheme.backgroundColor,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Yaklaşan'),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${billsViewModel.upcomingBills.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Gecikmiş'),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: billsViewModel.overdueBills.isEmpty
                              ? Colors.white.withOpacity(0.2)
                              : Colors.red.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${billsViewModel.overdueBills.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (billsViewModel.isLoading &&
              billsViewModel.upcomingBills.isEmpty &&
              billsViewModel.overdueBills.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Faturalar yükleniyor...',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          if (billsViewModel.errorMessage != null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Bir hata oluştu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      billsViewModel.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.read<BillsViewModel>().fetchBills(token),
                      icon: Icon(Icons.refresh),
                      label: Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBillsList(
                billsViewModel.upcomingBills,
                context,
                token,
                false,
              ),
              _buildBillsList(
                billsViewModel.overdueBills,
                context,
                token,
                true,
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBillDialog(context, token),
        icon: Icon(Icons.add),
        label: Text('Yeni Fatura'),
      ),
    );
  }

  Widget _buildBillsList(
    List<UpcomingBill> bills,
    BuildContext context,
    String token,
    bool isOverdueTab,
  ) {
    if (bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOverdueTab
                  ? Icons.check_circle_outline
                  : Icons.receipt_long_outlined,
              size: 80,
              color: isOverdueTab
                  ? Colors.green.shade300
                  : Colors.grey.shade300,
            ),
            SizedBox(height: 16),
            Text(
              isOverdueTab
                  ? 'Gecikmiş fatura yok! 🎉'
                  : 'Henüz fatura eklenmemiş',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              isOverdueTab
                  ? 'Tüm faturalarınız zamanında ödenmiş'
                  : 'Yeni fatura eklemek için + butonuna dokunun',
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<BillsViewModel>().fetchBills(token),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: bills.length,
        itemBuilder: (context, index) {
          final bill = bills[index];
          return _buildBillCard(bill, context, token);
        },
      ),
    );
  }

  Widget _buildBillCard(UpcomingBill bill, BuildContext context, String token) {
    final isOverdue = bill.status == 'Gecikti';
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: isOverdue ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isOverdue
            ? BorderSide(color: Colors.red.shade300, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showBillDetails(context, bill, token),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(bill.category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(bill.category),
                      color: _getCategoryColor(bill.category),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  // Bill Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(
                                  bill.category,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                bill.category,
                                style: TextStyle(
                                  color: _getCategoryColor(bill.category),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₺${bill.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (isOverdue)
                        Container(
                          margin: EdgeInsets.only(top: 4),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'GECİKTİ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Divider
              Divider(height: 1),
              SizedBox(height: 16),
              // Due Date Info
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Her ayın ${bill.dueDay}. günü',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? Colors.red.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isOverdue
                            ? Colors.red.shade200
                            : Colors.orange.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOverdue ? Icons.warning : Icons.access_time,
                          size: 14,
                          color: isOverdue
                              ? Colors.red.shade700
                              : Colors.orange.shade800,
                        ),
                        SizedBox(width: 4),
                        Text(
                          isOverdue
                              ? '${bill.daysDiff.abs()} gün gecikti'
                              : '${bill.daysDiff} gün kaldı',
                          style: TextStyle(
                            color: isOverdue
                                ? Colors.red.shade700
                                : Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _showPayBillDialog(context, bill, token),
                      icon: Icon(Icons.payment, size: 18),
                      label: Text('Öde'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showBillDetails(context, bill, token),
                      icon: Icon(Icons.info_outline, size: 18),
                      label: Text('Detay'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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

  void _showBillDetails(BuildContext context, UpcomingBill bill, String token) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(bill.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getCategoryIcon(bill.category),
                    color: _getCategoryColor(bill.category),
                    size: 28,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        bill.category,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Divider(),
            SizedBox(height: 16),
            // Details
            _buildDetailRow(
              Icons.attach_money,
              'Tutar',
              '₺${bill.amount.toStringAsFixed(2)}',
            ),
            SizedBox(height: 12),
            _buildDetailRow(
              Icons.calendar_today,
              'Ödeme Günü',
              'Her ayın ${bill.dueDay}. günü',
            ),
            SizedBox(height: 12),
            _buildDetailRow(Icons.repeat, 'Tekrar', bill.recurrence),
            SizedBox(height: 12),
            _buildDetailRow(
              bill.status == 'Gecikti' ? Icons.warning : Icons.access_time,
              'Durum',
              bill.status == 'Gecikti'
                  ? '${bill.daysDiff.abs()} gün gecikti'
                  : '${bill.daysDiff} gün kaldı',
              valueColor: bill.status == 'Gecikti'
                  ? Colors.red.shade700
                  : Colors.orange.shade800,
            ),
            SizedBox(height: 24),
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditBillDialog(context, bill, token);
                    },
                    icon: Icon(Icons.edit),
                    label: Text('Düzenle'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(context, bill, token);
                    },
                    icon: Icon(Icons.delete_outline),
                    label: Text('Sil'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  void _showAddBillDialog(BuildContext context, String token) {
    final viewModel = context.read<BillsViewModel>();
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final dueDayController = TextEditingController();
    String selectedCategory = 'Diğer';

    final categories = [
      'Elektrik',
      'Su',
      'Doğalgaz',
      'İnternet',
      'Telefon',
      'Kira',
      'Kredi Kartı',
      'Sigorta',
      'Diğer',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 12),
              Text('Yeni Fatura Ekle'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Fatura Adı',
                      hintText: 'örn: Elektrik Faturası',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    validator: (v) =>
                        v!.isEmpty ? 'Fatura adı zorunludur' : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: 'Tutar',
                      hintText: '0.00',
                      prefixIcon: Icon(Icons.attach_money),
                      suffixText: '₺',
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      if (v!.isEmpty) return 'Tutar zorunludur';
                      if (double.tryParse(v) == null)
                        return 'Geçerli bir tutar girin';
                      if (double.parse(v) <= 0)
                        return 'Tutar 0\'dan büyük olmalı';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: dueDayController,
                    decoration: InputDecoration(
                      labelText: 'Ödeme Günü',
                      hintText: '1-31 arası',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v!.isEmpty) return 'Ödeme günü zorunludur';
                      final day = int.tryParse(v);
                      if (day == null || day < 1 || day > 31) {
                        return '1-31 arası bir gün girin';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Kategori',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((category) {
                      final isSelected = selectedCategory == category;
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.2),
                        checkmarkColor: Theme.of(context).colorScheme.primary,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text('İptal'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('Ekle'),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final bill = Bill(
                  name: nameController.text.trim(),
                  amount: double.parse(amountController.text),
                  dueDay: int.parse(dueDayController.text),
                  category: selectedCategory,
                );

                Navigator.of(ctx).pop();

                final success = await viewModel.addBill(bill, token);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            success ? Icons.check_circle : Icons.error,
                            color: Colors.white,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              success
                                  ? 'Fatura başarıyla eklendi!'
                                  : 'Hata oluştu. Tekrar deneyin.',
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: success
                          ? Colors.green.shade600
                          : Colors.red.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBillDialog(
    BuildContext context,
    UpcomingBill bill,
    String token,
  ) {
    // Not: Backend'de PUT endpoint'i olmadığı için şimdilik gösterilmiyor
    // İleride eklenebilir
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Düzenleme özelliği yakında eklenecek'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPayBillDialog(
    BuildContext context,
    UpcomingBill bill,
    String token,
  ) {
    final viewModel = context.read<BillsViewModel>();
    final amountController = TextEditingController(
      text: bill.amount.toStringAsFixed(2),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.payment, color: Colors.green.shade600),
            SizedBox(width: 12),
            Expanded(child: Text('Fatura Öde')),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      bill.category,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Ödenecek Tutar',
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: '₺',
                  helperText: 'Varsayılan: ₺${bill.amount.toStringAsFixed(2)}',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v!.isEmpty) return 'Tutar zorunludur';
                  if (double.tryParse(v) == null)
                    return 'Geçerli bir tutar girin';
                  if (double.parse(v) <= 0) return 'Tutar 0\'dan büyük olmalı';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('İptal'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.check),
            label: Text('Ödemeyi Onayla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final amount = double.parse(amountController.text);
              Navigator.of(ctx).pop();

              final success = await viewModel.markAsPaid(
                bill.id,
                amount,
                token,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          success ? Icons.check_circle : Icons.error,
                          color: Colors.white,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            success
                                ? '${bill.name} başarıyla ödendi!'
                                : 'Ödeme sırasında hata oluştu.',
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: success
                        ? Colors.green.shade600
                        : Colors.red.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    UpcomingBill bill,
    String token,
  ) {
    final viewModel = context.read<BillsViewModel>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade600),
            SizedBox(width: 12),
            Text('Faturayı Sil'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu faturayı silmek istediğinizden emin misiniz?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${bill.category} • ₺${bill.amount.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Bu işlem geri alınamaz.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('İptal'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.delete),
            label: Text('Sil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();

              final success = await viewModel.removeBill(bill.id, token);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          success ? Icons.check_circle : Icons.error,
                          color: Colors.white,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            success
                                ? '${bill.name} silindi'
                                : 'Silme sırasında hata oluştu.',
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: success
                        ? Colors.green.shade600
                        : Colors.red.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Helper functions
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'elektrik':
        return Icons.bolt;
      case 'su':
        return Icons.water_drop;
      case 'doğalgaz':
        return Icons.local_fire_department;
      case 'internet':
        return Icons.wifi;
      case 'telefon':
        return Icons.phone;
      case 'kira':
        return Icons.home;
      case 'kredi kartı':
        return Icons.credit_card;
      case 'sigorta':
        return Icons.security;
      default:
        return Icons.receipt;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'elektrik':
        return Colors.amber;
      case 'su':
        return Colors.blue;
      case 'doğalgaz':
        return Colors.orange;
      case 'internet':
        return Colors.purple;
      case 'telefon':
        return Colors.green;
      case 'kira':
        return Colors.brown;
      case 'kredi kartı':
        return Colors.indigo;
      case 'sigorta':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
