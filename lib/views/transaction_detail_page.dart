import 'package:flutter/material.dart';
import 'package:test_borsa/utils/amount_parser.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../view_model/home_view_model.dart';
import '../view_model/add_transaction_view_model.dart';
import '../utils/error_handler.dart';

class TransactionDetailPage extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final homeViewModel = context.read<HomeViewModel>();
    final transactionViewModel = context.read<AddTransactionViewModel>();
    final category = homeViewModel.getCategoryById(transaction.categoryId);
    final isIncome = transaction.type == TransactionType.income;

    return Scaffold(
      appBar: AppBar(
        title: Text('İşlem Detayı'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            // Düzenle butonunda:
            onPressed: () =>
                _showEditDialog(context, homeViewModel, transactionViewModel),
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              _showDeleteDialog(context, homeViewModel, transactionViewModel);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tutar kartı
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isIncome
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : [Colors.red.shade400, Colors.red.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: Colors.white,
                    size: 40,
                  ),
                  SizedBox(height: 12),
                  Text(
                    isIncome ? 'Gelir' : 'Gider',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    homeViewModel.formatCurrency(transaction.amount),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Detaylar
            _buildDetailCard(context, [
              _buildDetailRow(
                'Açıklama',
                transaction.description.isEmpty
                    ? 'Açıklama yok'
                    : transaction.description,
                Icons.description,
              ),
              Divider(),
              _buildDetailRow(
                'Kategori',
                category?.name ?? 'Bilinmeyen',
                Icons.category,
              ),
              Divider(),
              _buildDetailRow(
                'Tarih',
                homeViewModel.formatDate(transaction.date),
                Icons.calendar_today,
              ),
              Divider(),
              _buildDetailRow(
                'Tam Tarih',
                '${transaction.date.day}/${transaction.date.month}/${transaction.date.year} ${transaction.date.hour}:${transaction.date.minute.toString().padLeft(2, '0')}',
                Icons.access_time,
              ),
              if (transaction.linkedGoalId != null) ...[
                Divider(),
                _buildDetailRow(
                  'Bağlı Hedef',
                  'Hedefe yönelik işlem',
                  Icons.flag,
                  valueColor: Colors.blue[700],
                ),
              ],
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    HomeViewModel homeViewModel,
    AddTransactionViewModel transactionViewModel,
  ) {
    // Tutar ve açıklama için controller'lar
    final descriptionController = TextEditingController(
      text: transaction.description,
    );
    final amountController = TextEditingController(
      text: transaction.amount.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('İşlemi Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Açıklama (eklerken olduğu gibi isteğe bağlı)
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Açıklama (İsteğe bağlı)',
                  border: OutlineInputBorder(),
                  hintText: 'Açıklama girin...',
                ),
                maxLength: 100,
              ),
              SizedBox(height: 16),

              // Tutar
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Tutar',
                  border: OutlineInputBorder(),
                  prefixText: '₺',
                  hintText: '0,00',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              // Dialog'un üstünde görünsün diye hatalar dialog context'iyle gösterilir
              final amount = parseAmount(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Geçerli bir tutar girin')),
                );
                return;
              }

              // Sayfa kapanmadan önce navigator/messenger referanslarını al
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              navigator.pop(); // Düzenleme dialog'unu kapat
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => Center(child: CircularProgressIndicator()),
              );

              final updatedTransaction = TransactionModel(
                id: transaction.id,
                userId: transaction.userId,
                amount: amount,
                description: descriptionController.text.trim(),
                categoryId: transaction.categoryId,
                type: transaction.type,
                date: transaction.date,
                linkedGoalId: transaction.linkedGoalId,
              );

              Object? error;
              var success = false;
              try {
                success = await transactionViewModel.updateTransaction(
                  userId: transaction.userId,
                  transactionId: transaction.id as String,
                  transaction: updatedTransaction,
                );
                if (success) await homeViewModel.refresh();
              } catch (e) {
                error = e;
              }

              navigator.pop(); // Loading'i kapat

              if (success) {
                // Detay sayfasını güncel bilgilerle yeniden aç
                navigator.pushReplacement(
                  MaterialPageRoute(
                    builder: (_) =>
                        TransactionDetailPage(transaction: updatedTransaction),
                  ),
                );
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('İşlem güncellendi'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (error != null && context.mounted) {
                ErrorHandler.showErrorSnackBar(context, error);
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Güncelleme başarısız'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    HomeViewModel homeViewModel,
    AddTransactionViewModel transactionViewModel,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('İşlemi Sil'),
        content: Text('Bu işlemi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              // Sayfa kapanmadan önce navigator/messenger referanslarını al
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              navigator.pop(); // Onay dialog'unu kapat
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => Center(child: CircularProgressIndicator()),
              );

              var success = false;
              try {
                success = await transactionViewModel.deleteTransaction(
                  userId: transaction.userId,
                  transactionId: transaction.id as String,
                );
                if (success) await homeViewModel.refresh();
              } catch (_) {
                success = false;
              }

              navigator.pop(); // Loading'i kapat
              if (success) navigator.pop(); // Detay sayfasını kapat

              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success ? 'İşlem silindi' : 'İşlem silinirken hata oluştu',
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Sil'),
          ),
        ],
      ),
    );
  }
}
