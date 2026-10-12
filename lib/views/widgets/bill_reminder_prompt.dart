import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/bill_reminder_service.dart';
import '../../view_model/bill_view_model.dart';
import 'ui/ui.dart';

/// Hatırlatmaları açar: bildirim iznini ister, verilirse mevcut faturalar
/// için hatırlatmaları hemen kurar. Sonucu kullanıcıya bildirir.
Future<bool> turnOnBillReminders(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final bills = context.read<BillsViewModel>();
  final ok = await BillReminders.enable();
  if (ok) {
    await bills.syncReminders();
    messenger.showSnackBar(const SnackBar(
      content: Text('Hatırlatmalar açık: son günden bir gün önce ve son gün 10:00\'da'),
    ));
  } else {
    messenger.showSnackBar(const SnackBar(
      content: Text('Bildirim izni verilmedi. Telefon ayarlarından açabilirsin.'),
    ));
  }
  return ok;
}

/// Faturalar ekranında, hatırlatmalar kapalıyken bir kez gösterilen öneri kartı
class BillReminderBanner extends StatefulWidget {
  const BillReminderBanner({super.key});

  @override
  State<BillReminderBanner> createState() => _BillReminderBannerState();
}

class _BillReminderBannerState extends State<BillReminderBanner> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final show = !await BillReminders.isEnabled() &&
        !await BillReminders.isBannerDismissed();
    if (mounted && show) setState(() => _visible = true);
  }

  Future<void> _turnOn() async {
    final ok = await turnOnBillReminders(context);
    if (ok && mounted) setState(() => _visible = false);
  }

  Future<void> _dismiss() async {
    await BillReminders.dismissBanner();
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: AppCard(
        color: c.primarySoft,
        borderColor: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, 4, AppSpace.md),
        child: Row(
          children: [
            Icon(Icons.notifications_active_outlined, color: c.primary),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Son ödeme gününü hatırlatalım mı?',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bir gün önce ve son gün bildirim gelir.',
                    style: TextStyle(color: c.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: _turnOn,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Aç'),
                      ),
                      TextButton(onPressed: _dismiss, child: const Text('Şimdi değil')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
