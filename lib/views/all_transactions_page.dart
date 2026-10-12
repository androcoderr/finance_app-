import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../view_model/home_view_model.dart';
import 'widgets/transaction_row.dart';
import 'widgets/ui/ui.dart';

/// Arama + tür / ay / kategori filtresi (saf fonksiyon; testlerde kullanılır).
/// [month] verilirse yalnızca o ayın işlemleri; [nameOf] kategori adını verir.
List<TransactionModel> filterTransactions(
  List<TransactionModel> list, {
  String query = '',
  TransactionType? type,
  DateTime? month,
  String? categoryId,
  String? Function(String categoryId)? nameOf,
}) {
  final q = trLower(query.trim());
  return list.where((t) {
    if (type != null && t.type != type) return false;
    if (categoryId != null && t.categoryId != categoryId) return false;
    if (month != null && (t.date.year != month.year || t.date.month != month.month)) {
      return false;
    }
    if (q.isNotEmpty) {
      final name = trLower(nameOf?.call(t.categoryId) ?? '');
      if (!trLower(t.description).contains(q) && !name.contains(q)) return false;
    }
    return true;
  }).toList();
}

/// Bütün işlemler: arama, filtre, güne göre gruplu liste
class AllTransactionsPage extends StatefulWidget {
  const AllTransactionsPage({super.key});

  @override
  State<AllTransactionsPage> createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends State<AllTransactionsPage> {
  final _search = TextEditingController();
  TransactionType? _type;
  DateTime? _month;
  Category? _category;

  static final _monthFmt = DateFormat('MMMM y', 'tr_TR');
  static final _dayFmt = DateFormat('d MMMM EEEE', 'tr_TR');

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(DateTime(d.year, d.month, d.day)).inDays;
    if (diff == 0) return 'Bugün';
    if (diff == 1) return 'Dün';
    final s = _dayFmt.format(d);
    return d.year == now.year ? s : '$s ${d.year}';
  }

  String _time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Future<void> _pickMonth(List<DateTime> months) async {
    final picked = await showModalBottomSheet<DateTime?>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('Tüm zamanlar'),
              trailing: _month == null ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, DateTime(0)),
            ),
            for (final m in months)
              ListTile(
                title: Text(trCapitalize(_monthFmt.format(m))),
                trailing: _month == m ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(ctx, m),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() => _month = picked.year == 0 ? null : picked);
  }

  Future<void> _pickCategory(List<Category> cats) async {
    final picked = await showModalBottomSheet<Category?>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          children: [
            ListTile(
              title: const Text('Tüm kategoriler'),
              trailing: _category == null ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, Category(id: '', name: '', isIncome: false)),
            ),
            for (final cat in cats)
              ListTile(
                leading: ToneIcon.category(cat.name, size: 34),
                title: Text(cat.name),
                trailing: _category?.id == cat.id ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(ctx, cat),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() => _category = picked.id.isEmpty ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final vm = context.watch<HomeViewModel>();
    final all = vm.allTransactions;
    String? nameOf(String id) => vm.getCategoryById(id)?.name;

    // Filtre seçenekleri: işlemi olan aylar ve kategoriler
    final months = {for (final t in all) DateTime(t.date.year, t.date.month)}.toList()
      ..sort((a, b) => b.compareTo(a));
    final usedCats = {for (final t in all) t.categoryId};
    final cats = vm.categories.where((x) => usedCats.contains(x.id)).toList()
      ..sort((a, b) => trCompare(a.name, b.name));

    final list = filterTransactions(
      all,
      query: _search.text,
      type: _type,
      month: _month,
      categoryId: _category?.id,
      nameOf: nameOf,
    );
    final income = list
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final expense = list
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
    final filtered = _search.text.trim().isNotEmpty ||
        _type != null ||
        _month != null ||
        _category != null;

    // Güne göre grupla (liste zaten yeniden eskiye sıralı)
    final rows = <Widget>[];
    DateTime? currentDay;
    var group = <TransactionModel>[];
    void flush() {
      if (group.isEmpty) return;
      final items = group;
      rows.add(Padding(
        padding: const EdgeInsets.fromLTRB(4, AppSpace.lg, 4, AppSpace.sm),
        child: Overline(_dayLabel(items.first.date)),
      ));
      rows.add(AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) Divider(indent: 70, height: 1, color: c.border),
              TransactionRow(
                t: items[i],
                categoryName: nameOf(items[i].categoryId),
                subtitle: _time(items[i].date),
                hidden: vm.secretMoney,
              ),
            ],
          ],
        ),
      ));
      group = [];
    }

    for (final t in list) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      if (currentDay != day) {
        flush();
        currentDay = day;
      }
      group.add(t);
    }
    flush();

    return Scaffold(
      appBar: AppBar(title: const Text('Tüm işlemler')),
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.xl),
          children: [
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Ara: açıklama ya da kategori',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => setState(_search.clear),
                      ),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (label, type) in [
                    ('Tümü', null),
                    ('Gider', TransactionType.expense),
                    ('Gelir', TransactionType.income),
                  ]) ...[
                    ChoiceChip(
                      label: Text(label),
                      selected: _type == type,
                      onSelected: (_) => setState(() => _type = type),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _FilterChip(
                    icon: Icons.calendar_month_outlined,
                    label: _month == null
                        ? 'Tüm zamanlar'
                        : trCapitalize(_monthFmt.format(_month!)),
                    active: _month != null,
                    onTap: () => _pickMonth(months),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    icon: Icons.category_outlined,
                    label: _category?.name ?? 'Kategori',
                    active: _category != null,
                    onTap: () => _pickCategory(cats),
                  ),
                ],
              ),
            ),
            if (list.isNotEmpty) ...[
              const SizedBox(height: AppSpace.md),
              Wrap(
                spacing: AppSpace.md,
                runSpacing: 4,
                children: [
                  Text('${list.length} işlem', style: TextStyle(color: c.textMuted)),
                  if (income > 0)
                    Text('Gelir ${vm.secretMoney ? Money.hidden : Money.format(income)}',
                        style: TextStyle(color: c.income, fontWeight: FontWeight.w600)),
                  if (expense > 0)
                    Text('Gider ${vm.secretMoney ? Money.hidden : Money.format(expense)}',
                        style: TextStyle(color: c.expense, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
            ...rows,
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 48),
                child: EmptyState(
                  icon: filtered ? Icons.search_off : Icons.receipt_outlined,
                  title: filtered ? 'Bu filtreye uyan işlem yok' : 'Henüz işlem yok',
                  subtitle: filtered
                      ? 'Aramayı ya da filtreleri değiştirmeyi dene.'
                      : 'Alttaki + butonuyla ilk gelir ya da giderini ekle.',
                  action: filtered
                      ? OutlinedButton(
                          onPressed: () => setState(() {
                            _search.clear();
                            _type = null;
                            _month = null;
                            _category = null;
                          }),
                          child: const Text('Filtreleri temizle'),
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Dokununca seçim listesi açan filtre çipi
class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: Icon(icon, size: 18),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 2),
          const Icon(Icons.expand_more, size: 18),
        ],
      ),
      selected: active,
      showCheckmark: false,
      onSelected: (_) => onTap(),
    );
  }
}

/// "ekim 2026" -> "Ekim 2026" (Türkçe i/İ doğru)
String trCapitalize(String s) =>
    s.isEmpty ? s : trUpper(s.substring(0, 1)) + s.substring(1);

/// Türkçe küçük harf: "I" -> "ı", "İ" -> "i" (Dart'ın toLowerCase'i "I"yı "i" yapar)
String trLower(String s) => s.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();

const _trAlphabet = 'abcçdefgğhıijklmnoöprsştuüvyz';

/// Türkçe alfabetik sıralama (Ç, Ğ, İ, Ö, Ş, Ü doğru yerde)
int trCompare(String a, String b) {
  final x = trLower(a), y = trLower(b);
  for (var i = 0; i < x.length && i < y.length; i++) {
    final p = _trAlphabet.indexOf(x[i]), q = _trAlphabet.indexOf(y[i]);
    final c = (p < 0 || q < 0) ? x[i].compareTo(y[i]) : p.compareTo(q);
    if (c != 0) return c;
  }
  return x.length.compareTo(y.length);
}
