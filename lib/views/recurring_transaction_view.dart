// lib/views/recurring_transactions_page.dart
import 'package:flutter/material.dart';
import 'widgets/ui/ui.dart';
import '../view_model/home_view_model.dart';
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
  State<RecurringTransactionsPage> createState() =>
      _RecurringTransactionsPageState();
}

class _RecurringTransactionsPageState extends State<RecurringTransactionsPage> {
  @override
  void initState() {
    super.initState();

    // build metodu tamamlandıktan sonra veriyi yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecurringTransactionViewModel>(
        context,
        listen: false,
      ).loadTransactions(context);
    });
  }

  static const _weekdays = [
    'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar',
  ];

  bool _isActive(RecurringTransaction t) =>
      t.endDate == null || !t.endDate!.isBefore(DateTime.now());

  /// Aylık karşılık (haftalık × 4,33, yıllık / 12 ...)
  double _monthlyEquivalent(RecurringTransaction t) => switch (t.frequency) {
        'daily' => t.amount * 30,
        'weekly' => t.amount * 52 / 12,
        'yearly' => t.amount / 12,
        _ => t.amount,
      };

  DateTime _addMonths(DateTime d, int months) {
    final m = d.month - 1 + months;
    final y = d.year + m ~/ 12;
    final month = m % 12 + 1;
    final last = DateTime(y, month + 1, 0).day;
    return DateTime(y, month, d.day > last ? last : d.day);
  }

  /// Bugün ve sonrası için ilk tekrar tarihi (bitmişse null)
  DateTime? _nextDate(RecurringTransaction t) {
    final today = DateUtils.dateOnly(DateTime.now());
    final start = DateUtils.dateOnly(t.startDate);
    for (var n = 0; n < 5000; n++) {
      final d = switch (t.frequency) {
        'daily' => start.add(Duration(days: n)),
        'weekly' => start.add(Duration(days: 7 * n)),
        'yearly' => _addMonths(start, 12 * n),
        _ => _addMonths(start, n),
      };
      if (t.endDate != null && d.isAfter(t.endDate!)) return null;
      if (!d.isBefore(today)) return d;
    }
    return null;
  }

  String _scheduleText(RecurringTransaction t) {
    final d = t.startDate;
    return switch (t.frequency) {
      'daily' => 'Her gün',
      'weekly' => 'Her hafta ${_weekdays[d.weekday - 1]}',
      'yearly' => 'Her yıl ${DateFormat('d MMMM', 'tr_TR').format(d)}',
      _ => 'Her ayın ${d.day}\'${_daySuffix(d.day)}',
    };
  }

  /// Türkçe ek: 1'i, 5'i, 6'sı, 10'u, 14'ü, 20'si ...
  String _daySuffix(int day) {
    const map = {
      1: 'i', 2: 'si', 3: 'ü', 4: 'ü', 5: 'i', 6: 'sı', 7: 'si', 8: 'i', 9: 'u',
      10: 'u', 20: 'si', 30: 'u',
    };
    return map[day] ?? map[day % 10]!;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final home = context.watch<HomeViewModel>();

    return Consumer<RecurringTransactionViewModel>(
      builder: (context, viewModel, child) {
        final all = [...viewModel.transactions]
          ..sort((a, b) {
            final na = _nextDate(a), nb = _nextDate(b);
            if (na == null) return 1;
            if (nb == null) return -1;
            return na.compareTo(nb);
          });
        final active = all.where(_isActive).toList();
        final monthlyExpense = active
            .where((t) => t.type == 'expense')
            .fold<double>(0, (s, t) => s + _monthlyEquivalent(t));
        final monthlyIncome = active
            .where((t) => t.type != 'expense')
            .fold<double>(0, (s, t) => s + _monthlyEquivalent(t));
        final next = active.where((t) => _nextDate(t) != null).firstOrNull;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tekrarlayan'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton.filled(
                  tooltip: 'Yeni tekrarlayan işlem',
                  style: IconButton.styleFrom(
                    backgroundColor: c.ink,
                    foregroundColor: c.onInk,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddEditTransactionPage(context, null, viewModel),
                ),
              ),
            ],
          ),
          body: viewModel.isLoading && all.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : viewModel.error != null && all.isEmpty
                  ? EmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Tekrarlayan işlemler yüklenemedi',
                      subtitle: '${viewModel.error}'.replaceFirst('Exception: ', ''),
                      action: OutlinedButton.icon(
                        onPressed: () => viewModel.loadTransactions(context),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tekrar dene'),
                      ),
                    )
                  : all.isEmpty
                      ? EmptyState(
                          icon: Icons.autorenew,
                          title: 'Tekrarlayan işlem yok',
                          subtitle: 'Maaş, kira, abonelikler… Bir kez ekle, her dönem otomatik kaydedilsin.',
                          action: SizedBox(
                            width: 200,
                            child: AppButton(
                              label: 'İşlem ekle',
                              icon: Icons.add,
                              onPressed: () =>
                                  _showAddEditTransactionPage(context, null, viewModel),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => viewModel.loadTransactions(context),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(
                                AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.xl),
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _SummaryTile(
                                      label: 'Aylık sabit gider',
                                      amount: monthlyExpense,
                                      fg: c.expense,
                                      bg: c.expenseSoft,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpace.md),
                                  Expanded(
                                    child: _SummaryTile(
                                      label: 'Aylık sabit gelir',
                                      amount: monthlyIncome,
                                      fg: c.income,
                                      bg: c.incomeSoft,
                                    ),
                                  ),
                                ],
                              ),
                              if (next != null) ...[
                                const SizedBox(height: AppSpace.xl),
                                Overline(_nextLabel(_nextDate(next)!)),
                                const SizedBox(height: AppSpace.sm),
                                _NextCard(
                                  title: _titleOf(next, home),
                                  subtitle: DateFormat('d MMMM, EEEE', 'tr_TR')
                                      .format(_nextDate(next)!),
                                  amount: next.amount,
                                  isIncome: next.type != 'expense',
                                  categoryName: home.getCategoryById(next.categoryId)?.name,
                                ),
                              ],
                              const SizedBox(height: AppSpace.xl),
                              const Overline('Tümü'),
                              const SizedBox(height: AppSpace.sm),
                              AppCard(
                                padding: EdgeInsets.zero,
                                child: Column(
                                  children: [
                                    for (var i = 0; i < all.length; i++) ...[
                                      if (i > 0)
                                        Divider(height: 1, indent: 70, color: c.border),
                                      _buildRow(context, all[i], viewModel, home),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
        );
      },
    );
  }

  String _nextLabel(DateTime d) {
    final days = d.difference(DateUtils.dateOnly(DateTime.now())).inDays;
    return days == 0 ? 'Sıradaki · bugün' : days == 1 ? 'Sıradaki · yarın' : 'Sıradaki · $days gün';
  }

  String _titleOf(RecurringTransaction t, HomeViewModel home) {
    final desc = t.description?.trim() ?? '';
    final cat = home.getCategoryById(t.categoryId)?.name;
    // Otomatik açıklamalar ("Konut (Tekrarlayan)") yerine kategori adı yeterli
    if (desc.isEmpty || desc.toLowerCase().contains('(tekrarlayan)')) {
      return cat ?? 'Tekrarlayan işlem';
    }
    return desc;
  }

  Widget _buildRow(
    BuildContext context,
    RecurringTransaction t,
    RecurringTransactionViewModel viewModel,
    HomeViewModel home,
  ) {
    final c = context.colors;
    final active = _isActive(t);
    final isIncome = t.type != 'expense';
    final categoryName = home.getCategoryById(t.categoryId)?.name;
    return InkWell(
      onTap: () => _showAddEditTransactionPage(context, t, viewModel),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
        child: Row(
          children: [
            Opacity(
              opacity: active ? 1 : 0.5,
              child: ToneIcon.category(categoryName, size: 42),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleOf(t, home),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: active ? c.text : c.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    active
                        ? _scheduleText(t)
                        : 'Sona erdi · ${DateFormat('d MMM y', 'tr_TR').format(t.endDate!)}',
                    style: TextStyle(fontSize: 12.5, color: c.textMuted),
                  ),
                ],
              ),
            ),
            Text(
              Money.format(isIncome ? t.amount : -t.amount, sign: isIncome),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: !active ? c.textMuted : (isIncome ? c.income : c.text),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 20, color: c.textFaint),
              onSelected: (v) {
                if (v == 'edit') _showAddEditTransactionPage(context, t, viewModel);
                if (v == 'delete') _deleteTransaction(context, t.id, viewModel);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Sil', style: TextStyle(color: c.expense)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditTransactionPage(
    BuildContext context,
    RecurringTransaction? transaction,
    RecurringTransactionViewModel viewModel,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Sayfa kapandıktan sonra mesajlar bu sayfanın context'iyle gösterilsin
        builder: (_) => AddEditRecurringTransactionPage(
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
              if (context.mounted) {
                viewModel.loadTransactions(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('İşlem kaydedildi!'),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
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
        if (context.mounted) {
          viewModel.loadTransactions(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('İşlem silindi'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showErrorSnackBar(context, e);
        }
      }
    }
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final double amount;
  final Color fg;
  final Color bg;
  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.fg,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Money.format(amount),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: context.colors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Sıradaki" koyu kartı
class _NextCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final bool isIncome;
  final String? categoryName;
  const _NextCard({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncome,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = CategoryStyle.of(categoryName);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.ink,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.tone(style.tone).foreground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(style.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.onInk, fontWeight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: c.onInk.withValues(alpha: 0.7), fontSize: 12.5),
                ),
              ],
            ),
          ),
          Text(
            Money.format(isIncome ? amount : -amount, sign: isIncome),
            style: TextStyle(
              color: c.onInk,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

