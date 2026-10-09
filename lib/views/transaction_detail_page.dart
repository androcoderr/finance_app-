import 'package:flutter/material.dart';
import 'package:test_borsa/utils/amount_parser.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../view_model/home_view_model.dart';
import '../view_model/add_transaction_view_model.dart';
import '../utils/error_handler.dart';
import 'package:intl/intl.dart';
import 'widgets/ui/ui.dart';

class TransactionDetailPage extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final homeViewModel = context.read<HomeViewModel>();
    final transactionViewModel = context.read<AddTransactionViewModel>();
    final category = homeViewModel.getCategoryById(transaction.categoryId);
    final isIncome = transaction.type == TransactionType.income;
    final style = CategoryStyle.of(category?.name);
    final tone = context.tone(style.tone);
    final hasNote = transaction.description.trim().isNotEmpty;

    Widget row(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: c.textFaint),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(color: c.textMuted)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: tone.background,
        actions: [
          IconButton(
            tooltip: 'Düzenle',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditDialog(context, homeViewModel, transactionViewModel),
          ),
          IconButton(
            tooltip: 'Sil',
            icon: Icon(Icons.delete_outline, color: c.expense),
            onPressed: () => _showDeleteDialog(context, homeViewModel, transactionViewModel),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: tone.background,
            padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: tone.foreground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(style.icon, color: Colors.white, size: 28),
                ),
                const SizedBox(height: AppSpace.lg),
                Text(
                  hasNote ? transaction.description.trim() : (category?.name ?? 'İşlem'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  Money.format(isIncome ? transaction.amount : -transaction.amount,
                      sign: true, decimals: true),
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                    color: isIncome ? c.income : c.text,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                StatusPill(
                  label: isIncome ? 'Gelir' : 'Gider',
                  icon: isIncome ? Icons.south_west : Icons.north_east,
                  foreground: isIncome ? c.income : c.expense,
                  background: c.surface,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.page),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  row(Icons.category_outlined, 'Kategori', category?.name ?? 'Bilinmiyor'),
                  Divider(height: 1, color: c.border),
                  row(Icons.event_outlined, 'Tarih',
                      DateFormat('d MMMM y, EEEE', 'tr_TR').format(transaction.date)),
                  Divider(height: 1, color: c.border),
                  row(Icons.schedule, 'Saat', DateFormat('HH:mm').format(transaction.date)),
                ],
              ),
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
