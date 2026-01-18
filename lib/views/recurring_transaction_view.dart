// lib/views/recurring_transactions_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/recurring_transaction_model.dart';
import '../view_model/recurring_transaction_view_model.dart';
import '../services/recurring_transaction_service.dart';
import '../utils/error_handler.dart';
import 'add_edit_recurring_transaction_page.dart';

class RecurringTransactionsPage extends StatefulWidget {
  final String userId;

  const RecurringTransactionsPage({super.key, required this.userId});

  @override
  _RecurringTransactionsPageState createState() =>
      _RecurringTransactionsPageState();
}

class _RecurringTransactionsPageState extends State<RecurringTransactionsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // build metodu tamamlandıktan sonra veriyi yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecurringTransactionViewModel>(
        context,
        listen: false,
      ).loadTransactions(context);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tema renklerine kolay erişim için değişkenler
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<RecurringTransactionViewModel>(
      builder: (context, viewModel, child) {
        final expenseTransactions = viewModel.expenseTransactions;
        final incomeTransactions = viewModel.incomeTransactions;

        return Scaffold(
          // 1. Değişiklik: Sabit renk yerine tema rengi
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            title: Text('Tekrarlayan İşlemler'),
            // 2. Değişiklik: Sabit renkleri kaldırarak temanın AppBar stilini kullanmasını sağladık
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () => viewModel.loadTransactions(context),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              // 3. Değişiklik: Sabit renkler yerine tema renkleri
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurface.withOpacity(0.7),
              indicatorColor: colorScheme.primary,
              tabs: [
                Tab(text: 'Giderler (${expenseTransactions.length})'),
                Tab(text: 'Gelirler (${incomeTransactions.length})'),
              ],
            ),
          ),
          body: viewModel.isLoading
              ? Center(child: CircularProgressIndicator())
              : viewModel.error != null
              ? Center(
                  child: Text(
                    'Veri Yükleme Hatası: ${viewModel.error}',
                    style: TextStyle(color: colorScheme.error),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTransactionsList(expenseTransactions, viewModel),
                    _buildTransactionsList(incomeTransactions, viewModel),
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                _showAddEditTransactionPage(context, null, viewModel),
            icon: Icon(Icons.add),
            label: Text('Yeni İşlem Ekle'),
            // 4. Değişiklik: Sabit renkler yerine tema renkleri
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
        );
      },
    );
  }

  Widget _buildTransactionsList(
    List<RecurringTransaction> transactionList,
    RecurringTransactionViewModel viewModel,
  ) {
    if (transactionList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 5. Değişiklik: Boş liste ikon ve metin renklerini tema duyarlı hale getirdik
            Icon(
              Icons.autorenew,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            SizedBox(height: 16),
            Text(
              'Henüz tekrarlayan işlem yok',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: transactionList.length,
      itemBuilder: (context, index) {
        final transaction = transactionList[index];
        return _buildTransactionCard(context, transaction, viewModel);
      },
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    RecurringTransaction transaction,
    RecurringTransactionViewModel viewModel,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isExpense = transaction.type == 'expense';
    final amountColor = isExpense ? Colors.red.shade600 : Colors.green.shade600;
    final icon = isExpense ? Icons.trending_down : Icons.trending_up;

    // 6. Değişiklik: Container yerine Card widget'ı kullanarak daha modern ve tema uyumlu bir görünüm elde ettik.
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () =>
            _showAddEditTransactionPage(context, transaction, viewModel),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: amountColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: amountColor),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description ??
                          (isExpense ? 'Gider' : 'Gelir'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    // 7. Değişiklik: Sabit gri renk yerine tema rengi
                    Text(
                      '${_getFrequencyText(transaction.frequency)} • ${_formatDate(transaction.startDate)} - ${_formatDate(transaction.endDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₺${_formatMoney(transaction.amount)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ),
                  ),
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert, size: 20),
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                      PopupMenuItem(
                        value: 'delete',
                        // 8. Değişiklik: Sabit kırmızı yerine temanın hata rengi
                        child: Text(
                          'Sil',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showAddEditTransactionPage(
                          context,
                          transaction,
                          viewModel,
                        );
                      } else if (value == 'delete') {
                        _deleteTransaction(context, transaction.id, viewModel);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMoney(double amount) {
    final formatter = NumberFormat('#,##0.00', 'tr_TR');
    return formatter.format(amount.abs());
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Süresiz';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _getFrequencyText(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'Günlük';
      case 'weekly':
        return 'Haftalık';
      case 'monthly':
        return 'Aylık';
      case 'yearly':
        return 'Yıllık';
      default:
        return 'Bilinmeyen';
    }
  }

  void _showAddEditTransactionPage(
    BuildContext context,
    RecurringTransaction? transaction,
    RecurringTransactionViewModel viewModel,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditRecurringTransactionPage(
          userId: widget.userId,
          transaction: transaction,
          onSave: (savedTransaction) async {
            try {
              if (transaction == null) {
                await RecurringTransactionService.createRecurringTransaction(
                  savedTransaction,
                );
              } else {
                await RecurringTransactionService.updateRecurringTransaction(
                  savedTransaction,
                );
              }
              if (mounted) {
                viewModel.loadTransactions(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('İşlem kaydedildi!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ErrorHandler.showErrorSnackBar(context, e);
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> _deleteTransaction(
    BuildContext context,
    String id,
    RecurringTransactionViewModel viewModel,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('İşlemi Sil'),
        content: Text(
          'Bu tekrarlayan işlemi silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            // 9. Değişiklik: Sabit kırmızı yerine temanın hata rengi
            child: Text(
              'Sil',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await RecurringTransactionService.deleteRecurringTransaction(id);
        if (mounted) {
          viewModel.loadTransactions(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('İşlem silindi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, e);
        }
      }
    }
  }
}
