import 'package:flutter/material.dart';
import 'package:test_borsa/views/home_page.dart';
import 'package:test_borsa/views/widgets/home_widget/receipt_scanner_page.dart';
import '../../../view_model/home_view_model.dart';
import '../../add_transaction_page.dart';
import '../../finance_screen.dart';

Widget buildBottomNavigationBar(BuildContext context, HomeViewModel viewModel) {
  ThemeData theme = Theme.of(context);
  return Container(
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(25),
          blurRadius: 10,
          offset: Offset(0, -5),
        ),
      ],
    ),
    child: BottomNavigationBar(
      currentIndex: viewModel.selectedIndex,
      onTap: (index) {
        viewModel.onBottomNavTap(index);

        // Sayfa yönlendirmesi burada yapılmalı
        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomePage()),
            );
            break;
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddTransactionPage()),
            ).then((_) => viewModel.onBottomNavTap(0));
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FinanceScreen()),
            ).then((_) => viewModel.onBottomNavTap(0));
            break;
          case 3:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ReceiptScannerScreen()),
            ).then((_) => viewModel.onBottomNavTap(0));
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: theme.canvasColor,
      selectedItemColor: Colors.blue[600],
      unselectedItemColor: Colors.grey[400],
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          activeIcon: Icon(Icons.home),
          label: 'Ana Sayfa',
        ),
        BottomNavigationBarItem(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add, color: Colors.white, size: 24),
          ),
          activeIcon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[700],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add, color: Colors.white, size: 24),
          ),
          label: 'Ekle',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.currency_exchange),
          activeIcon: Icon(Icons.currency_exchange),
          label: 'Döviz',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt),
          activeIcon: Icon(Icons.receipt),
          label: 'Fiş Kayıt',
        ),
      ],
    ),
  );
}
