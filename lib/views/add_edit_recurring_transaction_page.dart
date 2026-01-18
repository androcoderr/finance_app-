// MARK: - 2. Ekleme/Düzenleme Sayfası (AddEditRecurringTransactionPage)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/category_model.dart';
import '../models/recurring_transaction_model.dart';
import '../services/recurring_transaction_service.dart';

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
  _AddEditRecurringTransactionPageState createState() =>
      _AddEditRecurringTransactionPageState();
}

class _AddEditRecurringTransactionPageState
    extends State<AddEditRecurringTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
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

  @override
  void initState() {
    super.initState();
    loadCategories();

    if (widget.transaction != null) {
      _amountController.text = widget.transaction!.amount.toString();
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
  Widget build(BuildContext context) {
    _setSelectedDefaultCategory();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transaction == null
              ? 'Yeni Tekrarlayan İşlem'
              : 'İşlem Düzenle',
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Gelir / Gider Seçimi
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Gider'),
                    value: 'expense',
                    groupValue: _selectedType,
                    onChanged: (value) =>
                        setState(() => _selectedType = value!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Gelir'),
                    value: 'income',
                    groupValue: _selectedType,
                    onChanged: (value) =>
                        setState(() => _selectedType = value!),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Kategori Seçimi
            categoriesLoading
                ? Center(child: LinearProgressIndicator())
                : DropdownButtonFormField<Category>(
                    decoration: InputDecoration(
                      labelText: 'Kategori Seç',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.category),
                    ),
                    initialValue: _selectedCategory,
                    items: getFilteredCategories().map((Category category) {
                      return DropdownMenuItem<Category>(
                        value: category,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (Category? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null) return 'Lütfen bir kategori seçin';
                      return null;
                    },
                  ),

            SizedBox(height: 16),

            // Miktar
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Miktar',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.money),
                prefixText: '₺',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Miktar gerekli';
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0)
                  return 'Geçerli bir miktar girin';
                return null;
              },
            ),

            SizedBox(height: 16),

            // ❌ Açıklama (Kaldırıldı)

            // Sıklık (Frequency) Seçimi
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Tekrar Sıklığı',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.repeat),
              ),
              initialValue: _selectedFrequency,
              items: frequencyOptions
                  .map(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(frequencyDisplay[value]!),
                    ),
                  )
                  .toList(),
              onChanged: (String? newValue) =>
                  setState(() => _selectedFrequency = newValue!),
            ),

            SizedBox(height: 16),

            // Başlangıç Tarihi
            ListTile(
              title: Text('Başlangıç Tarihi'),
              subtitle: Text(
                _startDate != null
                    ? DateFormat('dd/MM/yyyy').format(_startDate!)
                    : 'Tarih seçilmedi',
              ),
              leading: Icon(Icons.calendar_today),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (date != null) {
                  setState(() => _startDate = date);
                }
              },
            ),

            // Bitiş Tarihi (Opsiyonel)
            ListTile(
              title: Text('Bitiş Tarihi (Opsiyonel)'),
              subtitle: Text(
                _endDate != null
                    ? DateFormat('dd/MM/yyyy').format(_endDate!)
                    : 'Süresiz',
              ),
              leading: Icon(Icons.event_busy),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_endDate != null)
                    IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () => setState(() => _endDate = null),
                    ),
                  Icon(Icons.arrow_forward_ios),
                ],
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                      _endDate ??
                      _startDate?.add(Duration(days: 365)) ??
                      DateTime.now().add(Duration(days: 365)),
                  firstDate: _startDate ?? DateTime.now(),
                  lastDate: DateTime(2101),
                );
                if (date != null) {
                  setState(() => _endDate = date);
                }
              },
            ),

            SizedBox(height: 32),

            // Kaydet butonu
            ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.transaction == null ? 'İşlem Oluştur' : 'Güncelle',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
      final String transactionDescription =
          '${_selectedCategory!.name} (Tekrarlayan)';

      final transaction = RecurringTransaction(
        id: widget.transaction?.id ?? 'temp_id',
        userId: widget.userId,
        amount: double.parse(_amountController.text),
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
