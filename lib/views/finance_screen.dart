import 'package:collection/collection.dart' show mergeSort;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/finance_model.dart';
import '../view_model/finance_view_model.dart';
import 'widgets/ui/ui.dart';

/// Döviz, altın, kripto ve borsa fiyatları (yalnızca bilgi amaçlı)
class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

enum _Market { all, currency, gold, crypto, bist }

class _FinanceScreenState extends State<FinanceScreen> {
  final _searchController = TextEditingController();
  _Market _market = _Market.all;

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

  List<FinanceModel> _itemsFor(FinanceViewModel vm, _Market m) => switch (m) {
        _Market.currency => vm.getCurrencyData(),
        _Market.gold => vm.getTurkishGoldData(),
        _Market.crypto => vm.getCryptoData(),
        _Market.bist => vm.getBISTData(),
        // Tümü: kullanıcıların en çok baktığı döviz önce gelsin
        _Market.all => () {
            final rank = {
              for (final x in vm.getCurrencyData()) x.name: 0,
              for (final x in vm.getTurkishGoldData()) x.name: 1,
              for (final x in vm.getCryptoData()) x.name: 2,
              for (final x in vm.getBISTData()) x.name: 3,
            };
            final list = [...vm.filteredData];
            mergeSort(list, compare: (a, b) => (rank[a.name] ?? 4).compareTo(rank[b.name] ?? 4));
            return list;
          }(),
      };

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
        // Verisi olmayan kategoriler gösterilmez (ör. kaynak kapalıysa)
        final markets = labels.keys
            .where((m) => m == _Market.all || _itemsFor(vm, m).isNotEmpty)
            .toList();
        final items = _itemsFor(vm, _market);
        final favorites = _market == _Market.all && vm.searchQuery.isEmpty
            ? vm.favoriteItems
            : <FinanceModel>[];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Piyasalar'),
            actions: [
              IconButton(
                tooltip: 'Yenile',
                onPressed: vm.isRefreshing ? null : vm.refreshData,
                icon: vm.isRefreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: vm.isLoading && vm.financeData.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : vm.hasError && vm.financeData.isEmpty
                  ? EmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Piyasa verileri alınamadı',
                      subtitle: 'İnternet bağlantını kontrol edip tekrar dene.',
                      action: OutlinedButton.icon(
                        onPressed: vm.refreshData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tekrar dene'),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: vm.refreshData,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.xl),
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
                                  Material(
                                    color: _market == m ? c.ink : c.surfaceMuted,
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                      onTap: () => setState(() => _market = m),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 9),
                                        child: Text(
                                          labels[m]!,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: _market == m ? c.onInk : c.text,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (favorites.isNotEmpty) ...[
                            const SizedBox(height: AppSpace.xl),
                            const Overline('Favoriler'),
                            const SizedBox(height: AppSpace.sm),
                            _List(items: favorites, vm: vm, onTap: _showDetail),
                          ],
                          const SizedBox(height: AppSpace.xl),
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
