import 'package:flutter/material.dart';
import 'widgets/ui/ui.dart';
import 'package:intl/intl.dart';
import 'package:test_borsa/utils/amount_parser.dart';
import 'package:provider/provider.dart';
import '../models/bill_model.dart';
import '../view_model/bill_view_model.dart';
import '../view_model/user_view_model.dart';

class BillsPage extends StatefulWidget {
  const BillsPage({super.key});

  @override
  _BillsPageState createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  bool _isInitialLoad = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialLoad) {
      final token = context.read<UserViewModel>().authToken;
      if (token != null) {
        // HATA DÜZELTME: Build sırasında state güncellemesini önlemek için microtask kullanıyoruz
        Future.microtask(() {
          if (mounted) context.read<BillsViewModel>().fetchBills(token);
        });
        _isInitialLoad = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final token = context.watch<UserViewModel>().authToken;
    final vm = context.watch<BillsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faturalarım'),
        actions: [
          if (token != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton.filled(
                tooltip: 'Yeni fatura',
                style: IconButton.styleFrom(
                  backgroundColor: c.ink,
                  foregroundColor: c.onInk,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                icon: const Icon(Icons.add),
                onPressed: () => _showAddBillDialog(context, token),
              ),
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (token == null) {
            return const EmptyState(
              icon: Icons.lock_outline,
              title: 'Oturum bulunamadı',
              subtitle: 'Faturalarını görmek için tekrar giriş yap.',
            );
          }
          final all = [...vm.overdueBills, ...vm.upcomingBills, ...vm.paidBills];
          if (vm.isLoading && all.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.errorMessage != null && all.isEmpty) {
            return EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Faturalar yüklenemedi',
              subtitle: vm.errorMessage,
              action: OutlinedButton.icon(
                onPressed: () => vm.fetchBills(token),
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar dene'),
              ),
            );
          }
          if (all.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Henüz fatura eklemedin',
              subtitle: 'Elektrik, internet, kira… Faturalarını ekle, ödeme günlerini kaçırma.',
              action: SizedBox(
                width: 200,
                child: AppButton(
                  label: 'Fatura ekle',
                  icon: Icons.add,
                  onPressed: () => _showAddBillDialog(context, token),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => vm.fetchBills(token),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.xl),
              children: [
                _BillsSummary(vm: vm),
                const SizedBox(height: AppSpace.lg),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < all.length; i++) ...[
                        if (i > 0) Divider(height: 1, indent: 70, color: c.border),
                        _buildBillRow(all[i], context, token),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Fatura durumuna göre metin ve renk
  (String, Color) _statusOf(UpcomingBill bill) {
    final c = context.colors;
    if (bill.status == 'Ödendi') return ('Bu ay ödendi', c.income);
    if (bill.status == 'Gecikti') {
      return ('${bill.daysDiff.abs()} gün gecikti', c.expense);
    }
    if (bill.daysDiff == 0) return ('Bugün son gün', c.warning);
    if (bill.daysDiff <= 3) return ('${bill.daysDiff} gün kaldı', c.warning);
    return ('Her ayın ${bill.dueDay}. günü · ${bill.daysDiff} gün', c.textMuted);
  }

  Widget _buildBillRow(UpcomingBill bill, BuildContext context, String token) {
    final c = context.colors;
    final isPaid = bill.status == 'Ödendi';
    final isOverdue = bill.status == 'Gecikti';
    final (statusText, statusColor) = _statusOf(bill);

    return InkWell(
      onTap: () => _showBillDetails(context, bill, token),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            isPaid
                ? const ToneIcon(icon: Icons.check, tone: Tone.green, size: 42)
                : ToneIcon.bill(bill.category, size: 42),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isPaid ? c.textMuted : c.text,
                      decoration: isPaid ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: statusColor,
                      fontWeight: statusColor == c.textMuted
                          ? FontWeight.w400
                          : FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Money.format(bill.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isPaid ? c.textMuted : c.text,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (!isPaid) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 30,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        backgroundColor: isOverdue ? c.ink : c.surfaceMuted,
                        foregroundColor: isOverdue ? c.onInk : c.text,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _showPayBillDialog(context, bill, token),
                      child: const Text('Öde'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBillDetails(BuildContext context, UpcomingBill bill, String token) {
    final (statusText, statusColor) = _statusOf(bill);
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        final c = sheetContext.colors;
        Widget row(String label, String value, {Color? color}) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Text(label, style: TextStyle(color: c.textMuted)),
                  const Spacer(),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: color ?? c.text,
                    ),
                  ),
                ],
              ),
            );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.page, 0, AppSpace.page, AppSpace.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ToneIcon.bill(bill.category, size: 52),
                    const SizedBox(width: AppSpace.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill.name,
                            style: Theme.of(sheetContext).textTheme.titleLarge,
                          ),
                          Text(bill.category, style: TextStyle(color: c.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.lg),
                row('Tutar', Money.format(bill.amount)),
                Divider(color: c.border),
                row('Ödeme günü', 'Her ayın ${bill.dueDay}. günü'),
                Divider(color: c.border),
                row('Durum', statusText, color: statusColor),
                const SizedBox(height: AppSpace.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showEditBillDialog(context, bill, token);
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Düzenle'),
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.expense,
                          side: BorderSide(color: c.expense.withValues(alpha: 0.4)),
                        ),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showDeleteConfirmation(context, bill, token);
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Sil'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Fatura ekleme/düzenleme formu (tam ekran). [existing] verilirse düzenleme.
  void _showAddBillDialog(
    BuildContext context,
    String token, {
    UpcomingBill? existing,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _BillFormPage(token: token, existing: existing),
      ),
    );
  }

  void _showEditBillDialog(
    BuildContext context,
    UpcomingBill bill,
    String token,
  ) {
    _showAddBillDialog(context, token, existing: bill);
  }

  void _showPayBillDialog(
    BuildContext context,
    UpcomingBill bill,
    String token,
  ) {
    // Dialog kapandıktan sonra da güvenle mesaj gösterebilmek için önceden al
    final messenger = ScaffoldMessenger.of(context);
    final viewModel = context.read<BillsViewModel>();
    final amountController = TextEditingController(
      text: bill.amount.toStringAsFixed(2),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.payment, color: Colors.green.shade600),
            SizedBox(width: 12),
            Expanded(child: Text('Fatura Öde')),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      bill.category,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Ödenecek Tutar',
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: '₺',
                  helperText: 'Varsayılan: ₺${bill.amount.toStringAsFixed(2)}',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v!.isEmpty) return 'Tutar zorunludur';
                  if (parseAmount(v) == null)
                    return 'Geçerli bir tutar girin';
                  if (parseAmount(v)! <= 0) return 'Tutar 0\'dan büyük olmalı';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('İptal'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.check),
            label: Text('Ödemeyi Onayla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final amount = parseAmount(amountController.text)!;
              Navigator.of(ctx).pop();

              final success = await viewModel.markAsPaid(
                bill.id,
                amount,
                token,
              );
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          success ? Icons.check_circle : Icons.error,
                          color: Colors.white,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            success
                                ? '${bill.name} başarıyla ödendi!'
                                : (viewModel.actionError ??
                                      'Ödeme sırasında hata oluştu.'),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: success
                        ? Colors.green.shade600
                        : Colors.red.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    UpcomingBill bill,
    String token,
  ) {
    // Dialog kapandıktan sonra da güvenle mesaj gösterebilmek için önceden al
    final messenger = ScaffoldMessenger.of(context);
    final viewModel = context.read<BillsViewModel>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade600),
            SizedBox(width: 12),
            Text('Faturayı Sil'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu faturayı silmek istediğinizden emin misiniz?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${bill.category} • ₺${bill.amount.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Bu işlem geri alınamaz.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('İptal'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.delete),
            label: Text('Sil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();

              final success = await viewModel.removeBill(bill.id, token);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          success ? Icons.check_circle : Icons.error,
                          color: Colors.white,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            success
                                ? '${bill.name} silindi'
                                : (viewModel.actionError ??
                                      'Silme sırasında hata oluştu.'),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: success
                        ? Colors.green.shade600
                        : Colors.red.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Helper functions
}

/// Üstteki koyu özet kartı: bu ay ödenecek toplam ve durum dağılımı
class _BillsSummary extends StatelessWidget {
  final BillsViewModel vm;
  const _BillsSummary({required this.vm});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    double sum(List<UpcomingBill> l) => l.fold(0.0, (s, b) => s + b.amount);
    final overdue = sum(vm.overdueBills);
    final upcoming = sum(vm.upcomingBills);
    final paid = sum(vm.paidBills);
    final remaining = overdue + upcoming;
    final total = overdue + upcoming + paid;
    final count = vm.overdueBills.length + vm.upcomingBills.length;
    final month = DateFormat('MMMM', 'tr_TR').format(DateTime.now());

    Widget legend(Color color, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(color: c.onInk.withValues(alpha: 0.75), fontSize: 12),
            ),
          ],
        );

    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: c.ink,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$month ayında kalan',
                style: TextStyle(color: c.onInk.withValues(alpha: 0.75), fontSize: 13),
              ),
              const Spacer(),
              Text(
                count == 0 ? 'Hepsi ödendi' : '$count fatura',
                style: TextStyle(
                  color: c.onInk,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          MoneyText(remaining, fontSize: 34, color: c.onInk),
          if (total > 0) ...[
            const SizedBox(height: AppSpace.lg),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    for (final (v, color) in [
                      (paid, c.income),
                      (overdue, c.expense),
                      (upcoming, c.warning),
                    ])
                      if (v > 0)
                        Expanded(
                          flex: (v / total * 1000).round().clamp(1, 1000),
                          child: Container(
                            margin: const EdgeInsets.only(right: 2),
                            color: color,
                          ),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                if (paid > 0) legend(c.income, 'Ödenen ${Money.format(paid)}'),
                if (overdue > 0) legend(c.expense, 'Geciken ${Money.format(overdue)}'),
                if (upcoming > 0) legend(c.warning, 'Bekleyen ${Money.format(upcoming)}'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}



class _BillFormPage extends StatefulWidget {
  final String token;
  final UpcomingBill? existing;
  const _BillFormPage({required this.token, this.existing});

  @override
  State<_BillFormPage> createState() => _BillFormPageState();
}

class _BillFormPageState extends State<_BillFormPage> {
  static const _categories = [
    'Elektrik', 'Su', 'Doğalgaz', 'İnternet', 'Telefon',
    'Kira', 'Kredi Kartı', 'Sigorta', 'Diğer',
  ];

  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.existing?.name);
  late final _amountController = TextEditingController(
    text: widget.existing == null
        ? null
        : NumberFormat('#,##0.##', 'tr_TR').format(widget.existing!.amount),
  );
  late String _category = widget.existing?.category ?? 'Elektrik';
  late int? _dueDay = widget.existing?.dueDay;
  bool _saving = false;
  bool _dayError = false;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    setState(() => _dayError = _dueDay == null);
    if (!valid || _dueDay == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final vm = context.read<BillsViewModel>();
    final bill = Bill(
      name: _nameController.text.trim().isEmpty ? _category : _nameController.text.trim(),
      amount: parseAmount(_amountController.text)!,
      dueDay: _dueDay!,
      category: _category,
    );
    setState(() => _saving = true);
    final ok = _isEdit
        ? await vm.updateBill(widget.existing!.id, bill, widget.token)
        : await vm.addBill(bill, widget.token);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Fatura güncellendi' : 'Fatura eklendi')),
      );
    } else {
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(content: Text(vm.actionError ?? 'Kaydedilemedi, tekrar dene')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Faturayı düzenle' : 'Yeni fatura'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.xl),
                children: [
                  const Overline('Kategori'),
                  const SizedBox(height: AppSpace.md),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.35,
                    children: [
                      for (final cat in _categories)
                        _BillCategoryTile(
                          name: cat,
                          selected: cat == _category,
                          onTap: () => setState(() => _category = cat),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xl),
                  LabeledField(
                    label: 'Fatura adı (isteğe bağlı)',
                    child: TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(hintText: 'Örn. $_category faturası'),
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  LabeledField(
                    label: 'Aylık tutar',
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(hintText: '0', prefixText: '₺ '),
                      validator: (v) {
                        final a = parseAmount(v);
                        if (v == null || v.isEmpty) return 'Tutar gerekli';
                        if (a == null || a <= 0) return 'Geçerli bir tutar gir';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  Row(
                    children: [
                      const Overline('Her ayın kaçında ödenir?'),
                      const Spacer(),
                      if (_dueDay != null)
                        Text(
                          'Her ayın $_dueDay. günü',
                          style: TextStyle(
                            color: c.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),
                  GridView.count(
                    crossAxisCount: 7,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    children: [
                      for (var d = 1; d <= 31; d++)
                        Material(
                          color: _dueDay == d ? c.primary : c.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            onTap: () => setState(() {
                              _dueDay = d;
                              _dayError = false;
                            }),
                            child: Center(
                              child: Text(
                                '$d',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _dueDay == d ? c.onPrimary : c.text,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (_dayError) ...[
                    const SizedBox(height: 8),
                    Text('Ödeme gününü seç', style: TextStyle(color: c.expense)),
                  ],
                  if (_dueDay != null && _dueDay! > 28) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Kısa aylarda ayın son günü hatırlatılır.',
                      style: TextStyle(color: c.textMuted, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.lg),
                child: AppButton(
                  label: _isEdit ? 'Kaydet' : 'Faturayı ekle',
                  icon: Icons.check,
                  loading: _saving,
                  onPressed: _save,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillCategoryTile extends StatelessWidget {
  final String name;
  final bool selected;
  final VoidCallback onTap;
  const _BillCategoryTile({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = BillCategoryStyle.of(name);
    final tone = context.tone(style.tone);
    return Material(
      color: selected ? tone.background : c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: selected ? tone.foreground : c.border,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ToneIcon(icon: style.icon, tone: style.tone, size: 32),
            const SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

