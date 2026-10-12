import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../services/category_service.dart';
import '../utils/amount_parser.dart';
import '../utils/error_handler.dart';
import '../view_model/add_transaction_view_model.dart';
import '../view_model/home_view_model.dart';
import '../view_model/user_view_model.dart';
import 'widgets/ui/ui.dart';

/// Tek ekranda işlem ekleme: tutar → tür → kategori → tarih/not → kaydet
class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountFocus = FocusNode();

  List<Category> _categories = [];
  bool _loadingCategories = true;
  bool _isIncome = false;
  String? _categoryId;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    // Ekran açılınca tutar alanına odaklan
    WidgetsBinding.instance.addPostFrameCallback((_) => _amountFocus.requestFocus());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final loaded = await CategoryService.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = loaded;
        _loadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCategories = false);
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  List<Category> get _visibleCategories =>
      _categories.where((c) => c.isIncome == _isIncome).toList();

  void _setType(bool income) {
    if (income == _isIncome) return;
    setState(() {
      _isIncome = income;
      _categoryId = null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null && mounted) {
      final now = DateTime.now();
      setState(() => _date = DateTime(
            picked.year,
            picked.month,
            picked.day,
            now.hour,
            now.minute,
          ));
    }
  }

  Future<void> _showDateOptions() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.today_outlined),
              title: const Text('Bugün'),
              onTap: () => Navigator.pop(ctx, 'today'),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Dün'),
              onTap: () => Navigator.pop(ctx, 'yesterday'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Başka bir tarih'),
              onTap: () => Navigator.pop(ctx, 'pick'),
            ),
            const SizedBox(height: AppSpace.sm),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'today') setState(() => _date = now);
    if (choice == 'yesterday') {
      setState(() => _date = now.subtract(const Duration(days: 1)));
    }
    if (choice == 'pick') await _pickDate();
  }

  Future<void> _editNote() async {
    final controller = TextEditingController(text: _noteController.text);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Not'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 100,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Örn. öğle yemeği'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      setState(() => _noteController.text = result.trim());
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final amount = parseAmount(_amountController.text);
    if (amount == null || amount <= 0) {
      messenger.showSnackBar(const SnackBar(content: Text('Geçerli bir tutar gir')));
      _amountFocus.requestFocus();
      return;
    }
    if (_categoryId == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Bir kategori seç')));
      return;
    }
    final userId = context.read<UserViewModel>().currentUser?.id;
    if (userId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Oturum bulunamadı, tekrar giriş yap')),
      );
      return;
    }

    setState(() => _saving = true);
    final vm = context.read<AddTransactionViewModel>();
    final home = context.read<HomeViewModel>();
    vm.setSelectedTabIndex(_isIncome ? 1 : 0);
    final success = await vm.addTransaction(
      userId: userId,
      amount: amount,
      categoryId: _categoryId!,
      description: _noteController.text.trim(),
      date: _date,
    );
    if (!mounted) return;

    if (success) {
      await home.refresh();
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${_isIncome ? 'Gelir' : 'Gider'} kaydedildi · ${Money.format(amount)}',
          ),
        ),
      );
    } else {
      setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Kaydedilemedi, lütfen tekrar dene')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = _isIncome ? c.income : c.expense;
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final isToday = _isSameDay(_date, now);
    final isYesterday = _isSameDay(_date, yesterday);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni işlem'),
        leading: IconButton(
          tooltip: 'Kapat',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
                children: [
                  // Gider / Gelir seçici
                  _TypeSwitch(isIncome: _isIncome, onChanged: _setType),
                  const SizedBox(height: 28),

                  // Büyük tutar alanı
                  Center(
                    child: IntrinsicWidth(
                      child: Semantics(
                        // Ekran okuyucu yalnızca "0" demesin
                        label: 'Tutar',
                        child: TextField(
                        controller: _amountController,
                        focusNode: _amountFocus,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        textAlign: TextAlign.center,
                        cursorColor: accent,
                        style: TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                          color: c.text,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        decoration: InputDecoration(
                          filled: false,
                          hintText: '0',
                          hintStyle: TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.w800,
                            color: c.textFaint.withValues(alpha: 0.5),
                          ),
                          prefixText: '₺',
                          prefixStyle: TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _DateChip(
                        label: isToday
                            ? 'Bugün'
                            : isYesterday
                                ? 'Dün'
                                : DateFormat('d MMMM', 'tr_TR').format(_date),
                        icon: Icons.calendar_today_outlined,
                        selected: !isToday,
                        onTap: _showDateOptions,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _DateChip(
                          label: _noteController.text.trim().isEmpty
                              ? 'Not ekle'
                              : _noteController.text.trim(),
                          icon: Icons.edit_note,
                          selected: _noteController.text.trim().isNotEmpty,
                          onTap: _editNote,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  Overline(_isIncome ? 'Gelir kategorisi' : 'Gider kategorisi'),
                  const SizedBox(height: AppSpace.md),
                  if (_loadingCategories)
                    const Padding(
                      padding: EdgeInsets.all(AppSpace.xl),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _visibleCategories.length,
                      // Yükseklik yazı boyutuyla büyür (büyük yazıda etiket taşmasın)
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        mainAxisExtent:
                            76 + MediaQuery.textScalerOf(context).scale(11.5) * 1.5,
                      ),
                      itemBuilder: (context, i) {
                        final cat = _visibleCategories[i];
                        return _CategoryTile(
                          category: cat,
                          selected: cat.id == _categoryId,
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            setState(() => _categoryId = cat.id);
                          },
                        );
                      },
                    ),
                  const SizedBox(height: AppSpace.xl),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.page,
                AppSpace.sm,
                AppSpace.page,
                AppSpace.lg,
              ),
              child: AppButton(
                label: _isIncome ? 'Geliri kaydet' : 'Gideri kaydet',
                icon: Icons.check,
                loading: _saving,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeSwitch extends StatelessWidget {
  final bool isIncome;
  final ValueChanged<bool> onChanged;
  const _TypeSwitch({required this.isIncome, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget option(String label, IconData icon, bool value, Color color) {
      final selected = isIncome == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 44,
            decoration: BoxDecoration(
              color: selected ? c.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: selected ? Border.all(color: c.border) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? color : c.textFaint),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? c.text : c.textFaint,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          option('Gider', Icons.north_east, false, c.expense),
          option('Gelir', Icons.south_west, true, c.income),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = CategoryStyle.of(category.name);
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ToneIcon(icon: style.icon, tone: style.tone, size: 38),
              const SizedBox(height: 6),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: c.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _DateChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: selected ? c.primarySoft : c.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: selected ? c.primary : c.textMuted),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? c.primary : c.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
