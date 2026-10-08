import 'package:flutter/material.dart';
import 'package:test_borsa/utils/feature_flags.dart';
import 'package:test_borsa/views/widgets/home_widget/receipt_scanner_page.dart';
import '../../../view_model/home_view_model.dart';
import '../../add_transaction_page.dart';
import '../../finance_screen.dart';
import '../ui/ui.dart';

/// Alt menü: Ana Sayfa · [Ekle] · Döviz (· Fiş, yapay zeka açıksa)
Widget buildBottomNavigationBar(BuildContext context, HomeViewModel viewModel) {
  final c = context.colors;

  void open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page))
        .then((_) => viewModel.onBottomNavTap(0));
  }

  return Container(
    decoration: BoxDecoration(
      color: c.surface,
      border: Border(top: BorderSide(color: c.border)),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 72,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Ana Sayfa',
              active: true,
              onTap: () {},
            ),
            // Ortadaki "Ekle": mavi yuvarlak + ikonu, altında etiket
            Expanded(
              child: InkWell(
                onTap: () => open(AddTransactionPage()),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: c.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(Icons.add, color: c.onPrimary, size: 26),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Ekle',
                      style: TextStyle(
                        color: c.textFaint,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _NavItem(
              icon: Icons.currency_exchange,
              activeIcon: Icons.currency_exchange,
              label: 'Döviz',
              active: false,
              onTap: () => open(FinanceScreen()),
            ),
            if (kAiEnabled)
              _NavItem(
                icon: Icons.receipt_outlined,
                activeIcon: Icons.receipt,
                label: 'Fiş Kayıt',
                active: false,
                onTap: () => open(ReceiptScannerScreen()),
              ),
          ],
        ),
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = active ? c.primary : c.textFaint;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
