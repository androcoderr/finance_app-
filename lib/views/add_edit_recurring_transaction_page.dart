// MARK: - 2. Ekleme/Düzenleme Sayfası (AddEditRecurringTransactionPage)

import 'package:flutter/material.dart';
import 'package:test_borsa/utils/amount_parser.dart';
import 'package:intl/intl.dart';

import '../models/category_model.dart';
import '../models/recurring_transaction_model.dart';
import '../services/recurring_transaction_service.dart';
import 'widgets/ui/ui.dart';

class AddEditRecurringTransactionPage extends StatefulWidget {
  final String userId;
  final RecurringTransaction? transaction;
  final Function(RecurringTransaction) onSave;

  const AddEditRecurringTransactionPage({
    super.key,
    required this.userId,
    this.transaction,
    required this.onSave,
  });

  @override
  State<AddEditRecurringTransactionPage> createState() =>
      _AddEditRecurringTransactionPageState();
}

class _AddEditRecurringTransactionPageState
    extends State<AddEditRecurringTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  // _descriptionController kaldırıldı

  // Kategori Durumları
  List<Category> allCategories = [];
  Category? _selectedCategory;
  bool categoriesLoading = true;

  String _selectedType = 'expense';
  String _selectedFrequency = 'monthly';

  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> frequencyOptions = [
    'daily',
    'weekly',
    'monthly',
    'yearly',
  ];
  final Map<String, String> frequencyDisplay = {
    'daily': 'Günlük',
    'weekly': 'Haftalık',
    'monthly': 'Aylık',
    'yearly': 'Yıllık',
  };

  DateTime _earliestStartDate() {
    final limit = DateTime.now().subtract(const Duration(days: 365));
    final current = _startDate;
    return current != null && current.isBefore(limit) ? current : limit;
  }

  @override
  void initState() {
    super.initState();
    loadCategories();

    if (widget.transaction != null) {
      _amountController.text =
          NumberFormat('#,##0.##', 'tr_TR').format(widget.transaction!.amount);
      // Otomatik açıklamalar ("Konut (Tekrarlayan)") ad alanına taşınmaz
      final desc = widget.transaction!.description?.trim() ?? '';
      if (!desc.toLowerCase().contains('(tekrarlayan)')) _nameController.text = desc;
      _selectedType = widget.transaction!.type;
      _selectedFrequency = widget.transaction!.frequency;
      _startDate = widget.transaction!.startDate;
      _endDate = widget.transaction!.endDate;
    } else {
      _startDate = DateTime.now();
    }
  }

  // MARK: Kategori Yükleme ve Yönetimi Metotları
  Future<void> loadCategories() async {
    try {
      final loadedCategories =
          await RecurringTransactionService.getCategories();
      setState(() {
        allCategories = loadedCategories;
        categoriesLoading = false;

        if (widget.transaction != null) {
          final filteredList = allCategories.where(
            (c) => c.id == widget.transaction!.categoryId,
          );

          if (filteredList.isNotEmpty) {
            _selectedCategory = filteredList.first;
          } else {
            _setSelectedDefaultCategory();
          }
        } else {
          _setSelectedDefaultCategory();
        }
      });
    } catch (e) {
      setState(() => categoriesLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kategori yüklenirken hata oluştu.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Category> getFilteredCategories() {
    final bool isIncome = _selectedType == 'income';
    return allCategories.where((c) => c.isIncome == isIncome).toList();
  }

  void _setSelectedDefaultCategory() {
    final filtered = getFilteredCategories();

    if (_selectedCategory == null ||
        !filtered.any((c) => c.id == _selectedCategory?.id)) {
      _selectedCategory = filtered.isNotEmpty ? filtered.first : null;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? (_startDate ?? DateTime.now()).add(const Duration(days: 365))),
      firstDate: start ? _earliestStartDate() : (_startDate ?? DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isEdit = widget.transaction != null;
    final isIncome = _selectedType == 'income';
    final categories = getFilteredCategories();

    Widget dateTile(String label, DateTime? value, String empty, VoidCallback onTap,
        {VoidCallback? onClear}) {
      return LabeledField(
        label: label,
        child: Material(
          color: c.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 17, color: c.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      value == null ? empty : DateFormat('d MMM y', 'tr_TR').format(value),
                      style: TextStyle(color: value == null ? c.textFaint : c.text),
                    ),
                  ),
                  if (value != null && onClear != null)
                    GestureDetector(
                      onTap: onClear,
                      child: Icon(Icons.close, size: 17, color: c.textMuted),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Tekrarlayanı düzenle' : 'Yeni tekrarlayan'),
        leading: IconButton(
          tooltip: 'Kapat',
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
                  // Gider / Gelir
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: c.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        for (final (value, label, icon, color) in [
                          ('expense', 'Gider', Icons.north_east, c.expense),
                          ('income', 'Gelir', Icons.south_west, c.income),
                        ])
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _selectedType = value;
                                _selectedCategory = null;
                                _setSelectedDefaultCategory();
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                height: 42,
                                decoration: BoxDecoration(
                                  color: _selectedType == value ? c.surface : Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                  border: _selectedType == value
                                      ? Border.all(color: c.border)
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(icon,
                                        size: 17,
                                        color: _selectedType == value ? color : c.textFaint),
                                    const SizedBox(width: 6),
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: _selectedType == value ? c.text : c.textFaint,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: LabeledField(
                          label: 'Ad (isteğe bağlı)',
                          child: TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: isIncome ? 'Örn. Maaş' : 'Örn. Netflix',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        flex: 4,
                        child: LabeledField(
                          label: 'Tutar',
                          child: TextFormField(
                            controller: _amountController,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              hintText: '0',
                              prefixText: '₺ ',
                            ),
                            validator: (value) {
                              final amount = parseAmount(value);
                              if (value == null || value.isEmpty) return 'Gerekli';
                              if (amount == null || amount <= 0) return 'Geçersiz';
                              return null;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xl),
                  const Overline('Ne sıklıkla?'),
                  const SizedBox(height: AppSpace.sm),
                  Row(
                    children: [
                      for (final f in frequencyOptions) ...[
                        if (f != frequencyOptions.first) const SizedBox(width: 6),
                        Expanded(
                          child: Material(
                            color: _selectedFrequency == f ? c.ink : c.surfaceMuted,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              onTap: () => setState(() => _selectedFrequency = f),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                child: Center(
                                  child: Text(
                                    frequencyDisplay[f]!,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: _selectedFrequency == f ? c.onInk : c.text,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Row(
                    children: [
                      Expanded(
                        child: dateTile('Başlangıç', _startDate, 'Seç',
                            () => _pickDate(start: true)),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: dateTile('Bitiş (isteğe bağlı)', _endDate, 'Süresiz',
                            () => _pickDate(start: false),
                            onClear: () => setState(() => _endDate = null)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xl),
                  Overline(isIncome ? 'Gelir kategorisi' : 'Gider kategorisi'),
                  const SizedBox(height: AppSpace.sm),
                  if (categoriesLoading)
                    const Padding(
                      padding: EdgeInsets.all(AppSpace.xl),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: categories.length,
                      // Yükseklik yazı boyutuyla büyür (büyük yazıda etiket taşmasın)
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        mainAxisExtent:
                            70 + MediaQuery.textScalerOf(context).scale(11.5) * 1.5,
                      ),
                      itemBuilder: (context, i) {
                        final cat = categories[i];
                        final selected = cat.id == _selectedCategory?.id;
                        final style = CategoryStyle.of(cat.name);
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
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              setState(() => _selectedCategory = cat);
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ToneIcon(icon: style.icon, tone: style.tone, size: 34),
                                const SizedBox(height: 5),
                                Text(
                                  cat.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.lg),
                child: AppButton(
                  label: isEdit ? 'Kaydet' : 'Tekrarlayanı ekle',
                  icon: Icons.check,
                  onPressed: _saveTransaction,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate() &&
        _startDate != null &&
        _selectedCategory != null) {
      // ✅ Açıklama, kategoriden otomatik olarak atanır.
      final name = _nameController.text.trim();
      final String transactionDescription =
          name.isNotEmpty ? name : '${_selectedCategory!.name} (Tekrarlayan)';

      final transaction = RecurringTransaction(
        id: widget.transaction?.id ?? 'temp_id',
        userId: widget.userId,
        amount: parseAmount(_amountController.text)!,
        categoryId: _selectedCategory!.id,
        description: transactionDescription,
        type: _selectedType,
        startDate: _startDate!,
        endDate: _endDate,
        frequency: _selectedFrequency,
      );

      widget.onSave(transaction);
      Navigator.pop(context);
    } else if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen bir kategori seçin.'),
          backgroundColor: Colors.orange,
        ),
      );
    } else if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Başlangıç tarihi gerekli.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
