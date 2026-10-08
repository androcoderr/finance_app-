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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                child: Material(
                  color: c.ink,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () => open(AddTransactionPage()),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: c.onInk, size: 22),
                        const SizedBox(width: 6),
                        Text(
                          'Ekle',
                          style: TextStyle(
                            color: c.onInk,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
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
