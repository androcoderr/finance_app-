// Hedef Detay Sayfası
import 'package:flutter/material.dart';
import '../ui/celebration.dart';
import 'package:test_borsa/utils/amount_parser.dart';

import '../../../models/goal_model.dart';
import '../../../services/goal_service.dart';
import '../../../utils/error_handler.dart';
import '../../goal_page.dart';
import 'package:intl/intl.dart';
import '../ui/ui.dart';
import 'goal_style.dart';

class GoalDetailPage extends StatefulWidget {
  final Goal goal;
  final VoidCallback onUpdate;

  const GoalDetailPage({super.key, required this.goal, required this.onUpdate});

  @override
  _GoalDetailPageState createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage> {
  late Goal currentGoal;

  @override
  void initState() {
    super.initState();
    currentGoal = widget.goal;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final g = currentGoal;
    final style = goalStyle(g);
    final tone = context.tone(style.tone);
    final progress = g.progress.clamp(0.0, 1.0);
    final remaining = (g.targetAmount - g.currentAmount).clamp(0.0, double.infinity);
    final isCompleted = g.progress >= 1.0;
    final isOverdue =
        g.targetDate != null && g.targetDate!.isBefore(DateTime.now()) && !isCompleted;
    final daysLeft = g.targetDate?.difference(DateTime.now()).inDays;
    double? monthly;
    if (g.targetDate != null && !isCompleted && !isOverdue) {
      final now = DateTime.now();
      var months = (g.targetDate!.year - now.year) * 12 + g.targetDate!.month - now.month;
      if (months < 1) months = 1;
      monthly = remaining / months;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: tone.background,
        actions: [
          IconButton(
            tooltip: 'Düzenle',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editGoal,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: tone.background,
            padding: const EdgeInsets.fromLTRB(
                AppSpace.page, 0, AppSpace.page, AppSpace.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: tone.foreground,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(style.icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: AppSpace.lg),
                    Expanded(
                      child: Text(
                        g.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Money.percent(progress * 100),
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.6,
                        color: c.text,
                        height: 1,
                      ),
                    ),
                    const Spacer(),
                    if (isCompleted)
                      StatusPill(
                        label: 'Tamamlandı',
                        icon: Icons.check,
                        foreground: c.income,
                        background: c.surface,
                      )
                    else if (isOverdue)
                      StatusPill(
                        label: 'Süresi geçti',
                        foreground: c.expense,
                        background: c.surface,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    color: tone.foreground,
                    backgroundColor: c.surface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${Money.format(g.currentAmount)} birikti · hedef ${Money.format(g.targetAmount)}',
                  style: TextStyle(color: c.textMuted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        label: 'Kalan',
                        value: Money.format(remaining),
                        icon: Icons.hourglass_bottom,
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: _Stat(
                        label: g.targetDate == null ? 'Son tarih' : 'Süre',
                        value: g.targetDate == null
                            ? 'Belirlenmedi'
                            : isCompleted
                                ? DateFormat('d MMM y', 'tr_TR').format(g.targetDate!)
                                : isOverdue
                                    ? '${-daysLeft!} gün geçti'
                                    : '$daysLeft gün',
                        icon: Icons.event_outlined,
                        valueColor: isOverdue ? c.expense : null,
                      ),
                    ),
                  ],
                ),
                if (monthly != null) ...[
                  const SizedBox(height: AppSpace.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpace.lg),
                    decoration: BoxDecoration(
                      color: c.ink,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Zamanında ulaşmak için',
                                style: TextStyle(
                                  color: c.onInk.withValues(alpha: 0.7),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${Money.format(monthly.ceilToDouble())} / ay',
                                style: TextStyle(
                                  color: c.onInk,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.savings_outlined, color: c.onInk, size: 30),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpace.xl),
                if (!isCompleted)
                  AppButton(
                    label: 'Birikim ekle',
                    icon: Icons.add,
                    onPressed: _showUpdateProgressDialog,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateProgressDialog() {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Birikim ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Biriken: ${Money.format(currentGoal.currentAmount)}'),
            Text('Hedef: ${Money.format(currentGoal.targetAmount)}'),
            SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Eklenecek tutar',
                prefixText: '₺',
                border: OutlineInputBorder(),
                helperText: 'Mevcut tutarın üzerine eklenir',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              final added = parseAmount(amountController.text);
              if (added != null && added > 0) {
                final newAmount = currentGoal.currentAmount + added;
                try {
                  await GoalService.updateProgress(currentGoal.id, newAmount);
                  // ⚠️ DEĞİŞTİ: updatedGoal yerine manuel güncelleme
                  setState(() {
                    currentGoal = currentGoal.copyWith(
                      currentAmount: newAmount,
                    );
                  });
                  widget.onUpdate();
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);

                  if (newAmount >= currentGoal.targetAmount) {
                    if (!mounted) return;
                    await showGoalCelebration(context, currentGoal.name);
                  }

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('İlerleme güncellendi!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ErrorHandler.showErrorSnackBar(context, e);
                }
              }
            },
            child: Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  void _editGoal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Form kapandıktan sonra mesajlar bu sayfanın context'iyle gösterilsin
        builder: (_) => AddEditGoalPage(
          userId: currentGoal.userId,
          goal: currentGoal,
          onSave: (updatedGoal) async {
            try {
              await GoalService.updateGoal(updatedGoal);
              // ⚠️ DEĞİŞTİ: newGoal yerine manuel güncelleme
              setState(() => currentGoal = updatedGoal);
              widget.onUpdate();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hedef güncellendi!'),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              if (!mounted) return;
              ErrorHandler.showErrorSnackBar(context, e);
            }
          },
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: c.textFaint),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: c.textMuted, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: valueColor ?? c.text,
            ),
          ),
        ],
      ),
    );
  }
}

