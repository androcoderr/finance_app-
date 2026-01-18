import 'package:flutter/material.dart';

import '../../../models/transaction_model.dart';
import '../../../view_model/home_view_model.dart';
import '../../transaction_detail_page.dart';

class RecentTransactionsWidget extends StatefulWidget {
  final HomeViewModel viewModel;
  final BuildContext context;

  const RecentTransactionsWidget({
    super.key,
    required this.viewModel,
    required this.context,
  });

  @override
  State<RecentTransactionsWidget> createState() =>
      _RecentTransactionsWidgetState();
}
// Eski bildirimleri düzeltmek için bu kodu bir yere ekleyip çalıştırın

class _RecentTransactionsWidgetState extends State<RecentTransactionsWidget> {
  bool showAll = false;

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    // print('=== DEBUG INFO ===');
    // print('Toplam transaction: ${widget.viewModel.recentTransactions.length}');
    // print('Toplam kategori: ${widget.viewModel.categories.length}');
    // print('Kategori listesi:');
    /*
    widget.viewModel.categories.forEach((category) {
      print(' - ${category.id}: ${category.name}');
    });*/
    // İlk 5 veya tümünü göster
    final transactions = showAll
        ? widget.viewModel.recentTransactions
        : widget.viewModel.recentTransactions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Son İşlemler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            if (widget.viewModel.recentTransactions.length > 5)
              TextButton(
                onPressed: () {
                  setState(() {
                    showAll = !showAll;
                  });
                },
                child: Text(showAll ? 'Daha Az Gör' : 'Tümünü Gör'),
              ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: transactions.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'Henüz işlem yapılmamış.',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  separatorBuilder: (context, index) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
              final category = widget.viewModel.getCategoryById(
                transaction.categoryId,
              );
              final isIncome = transaction.type == TransactionType.income;

              return ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: theme.canvasColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                ),
                title: Text(
                  category?.name ?? 'Bilinmeyen Kategori',

                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      widget.viewModel.formatDate(transaction.date),
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'}${widget.viewModel.formatCurrency(transaction.amount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isIncome ? Colors.green[600] : Colors.red[600],
                      ),
                    ),
                    if (transaction.linkedGoalId != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Hedef',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TransactionDetailPage(transaction: transaction),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// HomePage'de kullanmak için
Widget buildRecentTransactions(HomeViewModel viewModel, BuildContext context) {
  return RecentTransactionsWidget(viewModel: viewModel, context: context);
}
