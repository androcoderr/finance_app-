import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../utils/app_info.dart';
import '../../../view_model/home_view_model.dart';
import '../../../view_model/user_view_model.dart';
import '../../analysis_screen.dart';
import '../../bill_screen.dart';
import '../../goal_page.dart';
import '../../login_screen.dart';
import '../../recurring_transaction_view.dart';
import '../../settings_page.dart';
import '../../shopping_list_page.dart';
import '../ui/brand.dart';
import '../ui/ui.dart';

/// Ana sayfadaki sağ menü: sayfalara hızlı geçiş
class DrawerWidget extends StatelessWidget {
  final HomeViewModel viewModel;
  const DrawerWidget({super.key, required this.viewModel});

  Future<void> _logout(BuildContext context) async {
    await context.read<UserViewModel>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final user = viewModel.currentUser;
    final userId = viewModel.userId ?? '';

    void go(Widget page) {
      Navigator.pop(context); // Menüyü kapat
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }

    return Drawer(
      backgroundColor: c.background,
      shape: const RoundedRectangleBorder(),
      child: Column(
        children: [
          GridPattern(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Row(
                  children: [
                    InitialsAvatar(
                      name: user?.name,
                      size: 48,
                      background: Colors.white,
                      foreground: AppColors.brandBlue,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            user?.email ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.md, horizontal: 10),
              children: [
                _Item(
                  icon: Icons.track_changes_outlined,
                  tone: Tone.purple,
                  label: 'Hedeflerim',
                  badge: viewModel.goals.isEmpty ? null : '${viewModel.goals.length}',
                  onTap: () => go(GoalsPage(userId: userId)),
                ),
                _Item(
                  icon: Icons.receipt_long_outlined,
                  tone: Tone.yellow,
                  label: 'Faturalarım',
                  onTap: () => go(BillsPage()),
                ),
                _Item(
                  icon: Icons.autorenew,
                  tone: Tone.teal,
                  label: 'Tekrarlayan işlemler',
                  onTap: () => go(RecurringTransactionsPage(userId: userId)),
                ),
                _Item(
                  icon: Icons.bar_chart_outlined,
                  tone: Tone.orange,
                  label: 'Raporlar',
                  onTap: () => go(AnalysisScreen()),
                ),
                _Item(
                  icon: Icons.checklist_outlined,
                  tone: Tone.green,
                  label: 'Alışveriş listesi',
                  onTap: () => go(ShoppingListPage()),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  child: Divider(color: c.border),
                ),
                _Item(
                  icon: Icons.settings_outlined,
                  tone: Tone.grey,
                  label: 'Ayarlar',
                  onTap: () => go(const SettingsPage()),
                ),
                _Item(
                  icon: Icons.card_giftcard_outlined,
                  tone: Tone.pink,
                  label: 'Arkadaşına tavsiye et',
                  onTap: () => SharePlus.instance.share(ShareParams(
                    text: 'Harcamalarımı, faturalarımı ve birikim hedeflerimi $kAppName ile '
                        'takip ediyorum. Sen de dene:\n\n$kShareLinks',
                  )),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: Column(
                children: [
                  _Item(
                    icon: Icons.logout,
                    tone: Tone.red,
                    label: 'Çıkış yap',
                    labelColor: c.expense,
                    onTap: () => _logout(context),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'v$kAppVersion',
                    style: TextStyle(color: c.textFaint, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final Tone tone;
  final String label;
  final String? badge;
  final Color? labelColor;
  final VoidCallback onTap;

  const _Item({
    required this.icon,
    required this.tone,
    required this.label,
    required this.onTap,
    this.badge,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            ToneIcon(icon: icon, tone: tone, size: 38),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: labelColor ?? c.text,
                ),
              ),
            ),
            if (badge != null)
              StatusPill(label: badge!, foreground: c.primary, background: c.primarySoft),
          ],
        ),
      ),
    );
  }
}
