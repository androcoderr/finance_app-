// lib/views/analysis_screen.dart

import 'package:flutter/material.dart';
import '../view_model/export_view_model.dart';
import 'widgets/ui/ui.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../view_model/analysis_view_model.dart';
import '../view_model/home_view_model.dart';
import '../services/category_service.dart';

// import '../utils/export_utils.dart' as export_utils; // Bu satır kullanılmıyorsa kaldırılabilir

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  // Kategorileri cache'lemek için
  Map<String, String> _categoryNames = {};
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await _loadCategories();
        // Kısa bir gecikme ekleyerek Provider'ın hazır olduğundan emin oluyoruz
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) _loadData();
      }
    });
  }

  Future<void> _loadCategories() async {
    try {
      // Kategori servisi public (token gerektirmiyor)
      final categories = await CategoryService.getCategories();
      if (mounted) {
        setState(() {
          _categoryNames = {for (var cat in categories) cat.id: cat.name};
        });
      }
    } catch (e) {
      debugPrint('Kategoriler yüklenirken hata: $e');
      if (mounted) {
        setState(() {});
      }
    }
  }

  // GÜNCELLEME: _loadData metodu sadeleştirildi.
  void _loadData() {
    if (!mounted) return;

    // Sadece AnalysisViewModel'i almamız yeterli,
    // çünkü o zaten UserViewModel'e sahip.
    final analysisViewModel = Provider.of<AnalysisViewModel>(
      context,
      listen: false,
    );

    // Artık 'userId' parametresine gerek yok.
    // ViewModel, token'ı ve ID'yi kendisi alacak.
    analysisViewModel.loadAnalysisData();
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      await context.read<ExportViewModel>().generateAndExportReport(context);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalysisViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Raporlar'),
            actions: [
              IconButton(
                tooltip: 'PDF olarak paylaş',
                onPressed: _exporting ? null : _export,
                icon: _exporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: _buildBody(context, viewModel),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AnalysisViewModel viewModel) {
    final c = context.colors;
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.errorMessage != null) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Rapor yüklenemedi',
        subtitle: viewModel.errorMessage,
        action: OutlinedButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh),
          label: const Text('Tekrar dene'),
        ),
      );
    }
    final trend = viewModel.getMonthlyTrendData();
    final hasAny = trend.any((m) => m['income']! > 0 || m['expense']! > 0) ||
        viewModel.totalIncome != 0 ||
        viewModel.totalExpense != 0;
    if (!hasAny) {
      return const EmptyState(
        icon: Icons.bar_chart_outlined,
        title: 'Henüz rapor için veri yok',
        subtitle: 'Gelir ve giderlerini ekledikçe burada aylık özetini göreceksin.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.xl),
        children: [
          _buildFilterChips(viewModel),
          const SizedBox(height: AppSpace.xl),
          const Overline('Net'),
          const SizedBox(height: 6),
          MoneyText(
            viewModel.netBalance,
            fontSize: 38,
            color: viewModel.netBalance < 0 ? c.expense : c.text,
          ),
          if (viewModel.expenseChangePercentage != null) ...[
            const SizedBox(height: 8),
            _buildComparisonCard(viewModel),
          ],
          const SizedBox(height: AppSpace.lg),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Gelir',
                  amount: viewModel.totalIncome,
                  icon: Icons.south_west,
                  fg: c.income,
                  bg: c.incomeSoft,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: _StatTile(
                  label: 'Gider',
                  amount: viewModel.totalExpense,
                  icon: Icons.north_east,
                  fg: c.expense,
                  bg: c.expenseSoft,
                ),
              ),
            ],
          ),
          const SectionHeader(
            'Son 6 ay',
            padding: EdgeInsets.fromLTRB(0, AppSpace.xl, 0, AppSpace.md),
          ),
          AppCard(child: _buildMonthlyChart(trend)),
          const SectionHeader(
            'Harcama dağılımı',
            padding: EdgeInsets.fromLTRB(0, AppSpace.xl, 0, AppSpace.md),
          ),
          _buildBreakdown(viewModel),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AnalysisViewModel viewModel) {
    final c = context.colors;
    const options = [
      (DateFilter.thisMonth, 'Bu ay'),
      (DateFilter.lastMonth, 'Geçen ay'),
      (DateFilter.last3Months, 'Son 3 ay'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          for (final (filter, label) in options)
            Expanded(
              child: GestureDetector(
                onTap: () => viewModel.changeFilter(filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: viewModel.currentFilter == filter
                        ? c.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: viewModel.currentFilter == filter
                        ? Border.all(color: c.border)
                        : null,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: viewModel.currentFilter == filter
                          ? c.text
                          : c.textFaint,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(AnalysisViewModel viewModel) {
    final c = context.colors;
    final change = viewModel.expenseChangePercentage!;
    final (text, fg, bg, icon) = change > 0.05
        ? ('Giderlerin önceki döneme göre ${Money.percent(change * 100)} arttı',
            c.expense, c.expenseSoft, Icons.trending_up)
        : change < -0.05
            ? ('Giderlerin önceki döneme göre ${Money.percent(-change * 100)} azaldı',
                c.income, c.incomeSoft, Icons.trending_down)
            : ('Giderlerin önceki dönemle benzer', c.textMuted, c.surfaceMuted,
                Icons.trending_flat);
    return Align(
      alignment: Alignment.centerLeft,
      child: StatusPill(label: text, foreground: fg, background: bg, icon: icon),
    );
  }

  /// 6 aylık gelir (yeşil) / gider (kırmızı) çizgi grafiği
  Widget _buildMonthlyChart(List<Map<String, double>> trend) {
    final c = context.colors;
    final maxValue = trend.fold<double>(
      0,
      (m, d) => [m, d['income']!, d['expense']!].reduce((a, b) => a > b ? a : b),
    );
    final top = maxValue <= 0 ? 100.0 : maxValue * 1.15;
    const months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];

    String compact(double v) {
      if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1).replaceAll('.', ',')}M';
      if (v >= 1000) return '${(v / 1000).round()}B';
      return v.round().toString();
    }

    return Column(
      children: [
        Row(
          children: [
            _Legend(color: c.income, label: 'Gelir'),
            const SizedBox(width: AppSpace.lg),
            _Legend(color: c.expense, label: 'Gider'),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        Container(
          height: 190,
          padding: const EdgeInsets.only(right: 14, top: 8),
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: top,
              minX: 0,
              maxX: (trend.length - 1).toDouble(),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: top / 4,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: c.border, strokeWidth: 1, dashArray: [4, 4]),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: top / 4,
                    getTitlesWidget: (v, meta) => v == 0 || v >= top
                        ? const SizedBox.shrink()
                        : Text(compact(v),
                            style: TextStyle(color: c.textFaint, fontSize: 10.5)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: MediaQuery.textScalerOf(context).scale(12) * 1.4 + 10,
                    interval: 1,
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      if (v != i || i < 0 || i >= trend.length) {
                        return const SizedBox.shrink();
                      }
                      final m = trend[i]['month']!.toInt();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          months[m - 1],
                          style: TextStyle(
                            color: i == trend.length - 1 ? c.text : c.textFaint,
                            fontSize: 12,
                            fontWeight: i == trend.length - 1
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => c.ink,
                  getTooltipItems: (spots) => [
                    for (final s in spots)
                      LineTooltipItem(
                        '${s.barIndex == 0 ? 'Gelir' : 'Gider'}  ${Money.format(s.y)}',
                        TextStyle(color: c.onInk, fontWeight: FontWeight.w700, fontSize: 12.5),
                      ),
                  ],
                ),
              ),
              lineBarsData: [
                _line(trend, 'income', c.income),
                _line(trend, 'expense', c.expense),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Yumuşak eğri, noktalı ve altı hafif dolgulu tek çizgi
  LineChartBarData _line(List<Map<String, double>> trend, String key, Color color) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < trend.length; i++) FlSpot(i.toDouble(), trend[i][key]!),
      ],
      isCurved: true,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        getDotPainter: (spot, _, _, i) => FlDotCirclePainter(
          radius: i == trend.length - 1 ? 4.5 : 3,
          color: context.colors.surface,
          strokeWidth: 2.5,
          strokeColor: color,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }

  /// Ana sayfadaki gibi renkli dağılım çubuğu + kategori listesi
  Widget _buildBreakdown(AnalysisViewModel viewModel) {
    final c = context.colors;
    final brightness = Theme.of(context).brightness;
    final entries = viewModel.expenseSummary.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = viewModel.totalExpense;
    if (entries.isEmpty || total <= 0) {
      return const AppCard(
        child: EmptyState(
          icon: Icons.pie_chart_outline,
          title: 'Bu dönemde gider yok',
        ),
      );
    }
    return AppCard(
      child: Column(
        children: [
          _DonutChart(
            entries: entries,
            total: total,
            nameOf: _getCategoryName,
          ),
          const SizedBox(height: AppSpace.lg),
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  ToneIcon.category(_getCategoryName(e.key), size: 36),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getCategoryName(e.key),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: e.value / total,
                            minHeight: 4,
                            color: CategoryStyle.of(_getCategoryName(e.key))
                                .tone
                                .resolve(brightness)
                                .foreground,
                            backgroundColor: c.surfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Money.format(e.value),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        Money.percent(e.value / total * 100, decimals: 1),
                        style: TextStyle(color: c.textFaint, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getCategoryName(String categoryId) {
    // Önce cache'den (initState'te doldurulan) kontrol et
    if (_categoryNames.containsKey(categoryId)) {
      return _categoryNames[categoryId]!;
    }

    // Cache'de yoksa HomeViewModel'den (canlı) dene
    try {
      final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
      final category = homeViewModel.getCategoryById(categoryId);

      if (category != null) {
        return category.name;
      }
    } catch (e) {
      debugPrint('Category lookup error: $e');
    }

    // GÜNCELLEME: Eğer ID 'Diğer' değilse ve bulunamadıysa 'Bilinmeyen Kategori' döndür
    if (categoryId != 'Diğer') {
      return 'Bilinmeyen Kategori';
    }

    return categoryId; // 'Diğer' ise 'Diğer' olarak döner
  }

}

class _StatTile extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color fg;
  final Color bg;
  const _StatTile({
    required this.label,
    required this.amount,
    required this.icon,
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
          Row(
            children: [
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
            ],
          ),
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

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: context.colors.textMuted, fontSize: 13)),
        ],
      );
}

/// Etiketsiz halka grafik: ortada toplam; dilime dokununca o kategori gösterilir.
/// (Kategori adları ve yüzdeler altındaki listede — etiketler çakışmaz.)
class _DonutChart extends StatefulWidget {
  final List<MapEntry<String, double>> entries;
  final double total;
  final String Function(String id) nameOf;
  const _DonutChart({required this.entries, required this.total, required this.nameOf});

  @override
  State<_DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<_DonutChart> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final brightness = Theme.of(context).brightness;
    final selected = _touched != null && _touched! >= 0 && _touched! < widget.entries.length
        ? widget.entries[_touched!]
        : null;

    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 68,
              startDegreeOffset: -90,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (!event.isInterestedForInteractions) return;
                  final i = response?.touchedSection?.touchedSectionIndex;
                  // Ortaya veya dilim dışına dokunulunca -1 gelir: seçimi kaldır
                  setState(() => _touched = (i == null || i < 0) ? null : i);
                },
              ),
              sections: [
                for (var i = 0; i < widget.entries.length; i++)
                  PieChartSectionData(
                    value: widget.entries[i].value,
                    color: CategoryStyle.of(widget.nameOf(widget.entries[i].key))
                        .tone
                        .resolve(brightness)
                        .foreground,
                    radius: _touched == i ? 34 : 28,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          // Ortadaki boşluğa sığsın (büyük tutar / büyük yazı)
          SizedBox(
            width: 112,
            child: FitLine(
              alignment: Alignment.center,
              Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selected == null ? 'Toplam gider' : widget.nameOf(selected.key),
                style: TextStyle(color: c.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                Money.format(selected?.value ?? widget.total),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: c.text,
                ),
              ),
              if (selected != null)
                Text(
                  Money.percent(selected.value / widget.total * 100, decimals: 1),
                  style: TextStyle(color: c.textFaint, fontSize: 12.5),
                ),
            ],
          ),
            ),
          ),
        ],
      ),
    );
  }
}

