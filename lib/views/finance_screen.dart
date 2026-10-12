import 'package:collection/collection.dart' show mergeSort;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/finance_model.dart';
import '../view_model/finance_view_model.dart';
import 'widgets/ui/brand.dart';
import 'widgets/ui/ui.dart';

/// Döviz, altın, kripto ve borsa fiyatları (yalnızca bilgi amaçlı)
class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

enum _Market { all, currency, gold, crypto, bist }

enum _Sort { suggested, change, price, name }

class _FinanceScreenState extends State<FinanceScreen> {
  final _searchController = TextEditingController();
  _Market _market = _Market.all;
  _Sort _sort = _Sort.suggested;
  bool _desc = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FinanceViewModel>().loadDataWithCache();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Kategori sırası: kullanıcıların en çok baktığı döviz önce
  int _rank(FinanceViewModel vm, FinanceModel x) {
    if (vm.getCurrencyData().contains(x)) return 0;
    if (vm.getTurkishGoldData().contains(x)) return 1;
    if (vm.getCryptoData().contains(x)) return 2;
    if (vm.getBISTData().contains(x)) return 3;
    return 4;
  }

  List<FinanceModel> _itemsFor(FinanceViewModel vm, _Market m) {
    final base = switch (m) {
      _Market.currency => vm.getCurrencyData(),
      _Market.gold => vm.getTurkishGoldData(),
      _Market.crypto => vm.getCryptoData(),
      _Market.bist => vm.getBISTData(),
      _Market.all => vm.filteredData,
    };
    final q = vm.searchQuery.trim().toLowerCase();
    final list = base.where((x) => q.isEmpty || x.name.toLowerCase().contains(q)).toList();
    int cmp(FinanceModel a, FinanceModel b) => switch (_sort) {
          _Sort.change => a.changePercentage.compareTo(b.changePercentage),
          _Sort.price => a.price.compareTo(b.price),
          _Sort.name => a.name.compareTo(b.name),
          // Önce kategori, sonra kategorinin kendi sırası (USD, EUR, GBP…)
          _Sort.suggested => _rank(vm, a) != _rank(vm, b)
              ? _rank(vm, a).compareTo(_rank(vm, b))
              : vm.financeData.indexOf(a).compareTo(vm.financeData.indexOf(b)),
        };
    mergeSort(list, compare: (a, b) {
      final r = cmp(a, b);
      return _sort == _Sort.suggested ? r : (_desc ? -r : r);
    });
    return list;
  }

  void _setSort(_Sort s) => setState(() {
        if (_sort == s && s != _Sort.suggested) {
          _desc = !_desc;
        } else {
          _sort = s;
          _desc = s != _Sort.name; // isim A→Z, diğerleri büyükten küçüğe
        }
      });

  FinanceModel? _find(FinanceViewModel vm, String prefix) {
    for (final x in vm.financeData) {
      if (x.name.startsWith(prefix)) return x;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Consumer<FinanceViewModel>(
      builder: (context, vm, _) {
        const labels = {
          _Market.all: 'Tümü',
          _Market.currency: 'Döviz',
          _Market.gold: 'Altın',
          _Market.crypto: 'Kripto',
          _Market.bist: 'Borsa',
        };
        final markets = labels.keys
            .where((m) => m == _Market.all || _itemsFor(vm, m).isNotEmpty)
            .toList();
        final items = _itemsFor(vm, _market);
        final favorites = _market == _Market.all && vm.searchQuery.isEmpty
            ? vm.favoriteItems
            : <FinanceModel>[];
        final highlights = [
          ('Dolar', _find(vm, 'USD/TRY')),
          ('Euro', _find(vm, 'EUR/TRY')),
          ('Gram altın', _find(vm, 'Gram Altın')),
        ].where((h) => h.$2 != null).toList();
        final up = vm.financeData.where((x) => x.change > 0).length;
        final down = vm.financeData.where((x) => x.change < 0).length;

        return Scaffold(
          body: vm.isLoading && vm.financeData.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: vm.refreshData,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        pinned: true,
                        backgroundColor: AppColors.brandBlue,
                        foregroundColor: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        systemOverlayStyle: SystemUiOverlayStyle.light,
                        title: const Text('Piyasalar',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        actions: [
                          IconButton(
                            tooltip: 'Yenile',
                            onPressed: vm.isRefreshing ? null : vm.refreshData,
                            icon: vm.isRefreshing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.refresh, color: Colors.white),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                      SliverToBoxAdapter(
                        child: GridPattern(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                                AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.xl),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (highlights.isNotEmpty)
                                  Row(
                                    children: [
                                      for (var i = 0; i < highlights.length; i++) ...[
                                        if (i > 0) const SizedBox(width: 8),
                                        Expanded(
                                          child: _HighlightTile(
                                            label: highlights[i].$1,
                                            item: highlights[i].$2!,
                                            onTap: () => _showDetail(highlights[i].$2!),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                const SizedBox(height: AppSpace.lg),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 6,
                                  children: [
                                    _Stat(icon: Icons.list, text: '${vm.financeData.length} piyasa'),
                                    _Stat(icon: Icons.arrow_upward, text: '$up yükselen'),
                                    _Stat(icon: Icons.arrow_downward, text: '$down düşen'),
                                    _Stat(icon: Icons.star_outline,
                                        text: '${vm.favoriteItems.length} favori'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (vm.hasError && vm.financeData.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyState(
                            icon: Icons.cloud_off_outlined,
                            title: 'Piyasa verileri alınamadı',
                            subtitle: 'İnternet bağlantını kontrol edip tekrar dene.',
                            action: OutlinedButton.icon(
                              onPressed: vm.refreshData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tekrar dene'),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpace.page, AppSpace.lg, AppSpace.page, AppSpace.xl),
                          sliver: SliverList.list(
                            children: [
                              TextField(
                                controller: _searchController,
                                onChanged: vm.updateSearchQuery,
                                decoration: InputDecoration(
                                  hintText: 'Ara: dolar, altın, bitcoin…',
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  suffixIcon: vm.searchQuery.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: 'Aramayı temizle',
                                          icon: const Icon(Icons.close, size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            vm.updateSearchQuery('');
                                          },
                                        ),
                                ),
                              ),
                              const SizedBox(height: AppSpace.md),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    for (final m in markets) ...[
                                      if (m != markets.first) const SizedBox(width: 8),
                                      _Chip(
                                        label: labels[m]!,
                                        selected: _market == m,
                                        onTap: () => setState(() => _market = m),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpace.md),
                              _SortBar(sort: _sort, desc: _desc, onChanged: _setSort),
                              if (favorites.isNotEmpty) ...[
                                const SizedBox(height: AppSpace.lg),
                                const Overline('Favoriler'),
                                const SizedBox(height: AppSpace.sm),
                                _List(items: favorites, vm: vm, onTap: _showDetail),
                              ],
                              const SizedBox(height: AppSpace.lg),
                              if (items.isEmpty)
                                EmptyState(
                                  icon: Icons.search_off,
                                  title: vm.searchQuery.isEmpty
                                      ? 'Bu kategoride veri yok'
                                      : '"${vm.searchQuery}" için sonuç yok',
                                )
                              else
                                _List(items: items, vm: vm, onTap: _showDetail),
                              const SizedBox(height: AppSpace.lg),
                              Text(
                                '${vm.lastUpdateTime.isEmpty ? '' : 'Son güncelleme ${vm.lastUpdateTime} · '}'
                                'Veriler bilgi amaçlıdır, gecikmeli olabilir; yatırım tavsiyesi değildir.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: c.textFaint, fontSize: 12, height: 1.4),
                              ),
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

  void _showDetail(FinanceModel item) {
    final vm = context.read<FinanceViewModel>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final c = ctx.colors;
        final up = item.change >= 0;
        Widget row(String label, String value, {Color? color}) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Text(label, style: TextStyle(color: c.textMuted)),
                  const Spacer(),
                  Text(value,
                      style: TextStyle(fontWeight: FontWeight.w700, color: color ?? c.text)),
                ],
              ),
            );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _Symbol(item: item, size: 48),
                    const SizedBox(width: AppSpace.lg),
                    Expanded(
                      child: Text(item.name, style: Theme.of(ctx).textTheme.titleLarge),
                    ),
                    StatefulBuilder(
                      builder: (ctx, setSheet) => IconButton(
                        tooltip: vm.isFavorite(item.name)
                            ? 'Favorilerden çıkar'
                            : 'Favorilere ekle',
                        icon: Icon(
                          vm.isFavorite(item.name) ? Icons.star : Icons.star_border,
                          color: vm.isFavorite(item.name) ? c.warning : c.textFaint,
                        ),
                        onPressed: () {
                          vm.toggleFavorite(item.name);
                          setSheet(() {});
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.lg),
                Text(
                  _price(item),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                row('Değişim',
                    '${up ? '+' : '−'}${_number(item.change.abs())}',
                    color: up ? c.income : c.expense),
                Divider(color: c.border),
                row('Değişim %', _percent(item), color: up ? c.income : c.expense),
                Divider(color: c.border),
                row('Güncelleme', DateFormat('HH:mm').format(item.lastUpdate)),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Mavi alandaki öne çıkan kur kutusu (Dolar, Euro, Gram altın)
class _HighlightTile extends StatelessWidget {
  final String label;
  final FinanceModel item;
  final VoidCallback onTap;
  const _HighlightTile({required this.label, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final up = item.change >= 0;
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FitLine(Text(label,
                  maxLines: 1,
                  style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12.5))),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _price(item),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FitLine(Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: up ? const Color(0xFF3FD38E) : const Color(0xFFFF8A8A),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  _percent(item),
                  maxLines: 1,
                  style: const TextStyle(
                    color: Color(0xFF0B1B33),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Stat({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xCCFFFFFF)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13)),
        ],
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: selected ? c.ink : c.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? c.onInk : c.text,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Sırala: Önerilen · Değişim ↓ · Fiyat · İsim"
class _SortBar extends StatelessWidget {
  final _Sort sort;
  final bool desc;
  final ValueChanged<_Sort> onChanged;
  const _SortBar({required this.sort, required this.desc, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const labels = {
      _Sort.suggested: 'Önerilen',
      _Sort.change: 'Değişim',
      _Sort.price: 'Fiyat',
      _Sort.name: 'İsim',
    };
    return Row(
      children: [
        Text('Sırala', style: TextStyle(color: c.textFaint, fontSize: 13)),
        const SizedBox(width: 6),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final s in labels.keys)
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => onChanged(s),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        children: [
                          Text(
                            labels[s]!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: sort == s ? FontWeight.w800 : FontWeight.w500,
                              color: sort == s ? c.primary : c.textMuted,
                            ),
                          ),
                          if (sort == s && s != _Sort.suggested)
                            Icon(
                              desc ? Icons.arrow_downward : Icons.arrow_upward,
                              size: 14,
                              color: c.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _number(double v) =>
    NumberFormat(v >= 1 ? '#,##0.00' : '#,##0.0000', 'tr_TR').format(v);

/// "$4.145,30", "₺49,21", borsa endeksleri için birimsiz "12.064,12"
String _price(FinanceModel item) {
  final symbol = switch (item.currency) {
    '₺' => '₺',
    '\$' => '\$',
    _ => '',
  };
  return '$symbol${_number(item.price)}';
}

String _percent(FinanceModel item) {
  final p = item.changePercentage;
  return '${item.change >= 0 ? '+' : '−'}${Money.percent(p.abs(), decimals: 2)}';
}

class _List extends StatelessWidget {
  final List<FinanceModel> items;
  final FinanceViewModel vm;
  final void Function(FinanceModel) onTap;
  const _List({required this.items, required this.vm, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 68, color: c.border),
            _Row(item: items[i], vm: vm, onTap: () => onTap(items[i])),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final FinanceModel item;
  final FinanceViewModel vm;
  final VoidCallback onTap;
  const _Row({required this.item, required this.vm, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final up = item.change >= 0;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _Symbol(item: item, size: 40),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (vm.isFavorite(item.name)) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.star, size: 14, color: c.warning),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _price(item),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 3),
                StatusPill(
                  label: _percent(item),
                  foreground: up ? c.income : c.expense,
                  background: up ? c.incomeSoft : c.expenseSoft,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Kalem için renkli kısa sembol kutusu (USD, BTC, XAU…)
class _Symbol extends StatelessWidget {
  final FinanceModel item;
  final double size;
  const _Symbol({required this.item, required this.size});

  @override
  Widget build(BuildContext context) {
    final name = item.name;
    final (text, tone) = switch (name) {
      _ when name.startsWith('USD') => ('\$', Tone.green),
      _ when name.startsWith('EUR') => ('€', Tone.blue),
      _ when name.startsWith('GBP') => ('£', Tone.purple),
      _ when name.contains('Altın') => ('Au', Tone.yellow),
      _ when name.contains('Gümüş') => ('Ag', Tone.grey),
      _ when name.contains('BIST') => ('BI', Tone.teal),
      _ when name.contains('(') =>
        (name.substring(name.indexOf('(') + 1, name.indexOf(')')), Tone.orange),
      _ => (name.characters.first, Tone.grey),
    };
    final t = context.tone(tone);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.background,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          color: t.foreground,
          fontWeight: FontWeight.w800,
          fontSize: text.length > 2 ? size * 0.26 : size * 0.38,
        ),
      ),
    );
  }
}
