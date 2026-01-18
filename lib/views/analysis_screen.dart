// lib/views/analysis_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
  final moneyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  // GlobalKey'ler (Kullanılmıyorsa kaldırılabilir)
  final GlobalKey _lineChartKey = GlobalKey();
  final GlobalKey _pieChartKey = GlobalKey();
  final GlobalKey _summaryCardsKey = GlobalKey();

  // Kategorileri cache'lemek için
  Map<String, String> _categoryNames = {};
  bool _categoriesLoaded = false;

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
          _categoriesLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Kategoriler yüklenirken hata: $e');
      if (mounted) {
        setState(() {
          _categoriesLoaded = true;
        });
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

  @override
  Widget build(BuildContext context) {
    // Consumer'ı ve ana Scaffold'u her zaman oluştur
    // GÜNCELLEME: Artık UserViewModel'i dinlemeye gerek yok
    return Consumer<AnalysisViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Finansal Raporlar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData, // Veriyi yenile
              ),
              // TODO: PDF Export butonu buraya eklenebilir
              // IconButton(
              //   icon: const Icon(Icons.picture_as_pdf),
              //   onPressed: () {
              //     // ExportViewModel'i çağır
              //   },
              // ),
            ],
          ),
          body: _buildBody(context, viewModel),
        );
      },
    );
  }

  // EKRAN GÖVDESİNİ OLUŞTURAN YARDIMCI METOT
  Widget _buildBody(BuildContext context, AnalysisViewModel viewModel) {
    // 1. Yüklenme Durumu
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Hata Durumu
    if (viewModel.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Hata: ${viewModel.errorMessage!}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    // 3. "Veri Yok" Kontrolü
    final bool hasCurrentMonthData =
        viewModel.totalExpense != 0 || viewModel.totalIncome != 0;
    final bool hasHistoricalData = viewModel.getMonthlyTrendData().isNotEmpty;

    if (!hasCurrentMonthData && !hasHistoricalData) {
      return const Center(
        child: Text('Henüz görüntülenecek bir finansal veri bulunmamaktadır.'),
      );
    }

    // 4. Ana İçerik
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Özet Kartlar
          _buildSummaryCards(viewModel),
          const SizedBox(height: 20),

          // GÜNCELLEME: Filtre Butonları (Opsiyonel ama önerilir)
          _buildFilterChips(viewModel),
          const SizedBox(height: 20),

          // 2. Aylık Trend Grafiği
          const Text(
            'Son 6 Aylık Gelir/Gider Trendi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildMonthlyLineChart(viewModel),
          const SizedBox(height: 30),

          // 3. Harcama Dağılım Grafiği
          const Text(
            'Harcama Dağılımı (Seçili Dönem)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildPieChart(viewModel),
          const SizedBox(height: 20),

          // 4. Detaylı Gider Listesi
          const Text(
            'Kategori Bazlı Giderler (Seçili Dönem)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          _buildExpenseList(viewModel),
        ],
      ),
    );
  }

  // MARK: - Widget Metotları

  // YENİ: Filtre çipleri
  Widget _buildFilterChips(AnalysisViewModel viewModel) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ChoiceChip(
            label: const Text('Bu Ay'),
            selected: viewModel.currentFilter == DateFilter.thisMonth,
            onSelected: (selected) =>
                viewModel.changeFilter(DateFilter.thisMonth),
            selectedColor: Colors.blue[100],
            backgroundColor: Colors.grey[200],
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Geçen Ay'),
            selected: viewModel.currentFilter == DateFilter.lastMonth,
            onSelected: (selected) =>
                viewModel.changeFilter(DateFilter.lastMonth),
            selectedColor: Colors.blue[100],
            backgroundColor: Colors.grey[200],
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Son 3 Ay'),
            selected: viewModel.currentFilter == DateFilter.last3Months,
            onSelected: (selected) =>
                viewModel.changeFilter(DateFilter.last3Months),
            selectedColor: Colors.blue[100],
            backgroundColor: Colors.grey[200],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(AnalysisViewModel viewModel) {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard('Gelir', viewModel.totalIncome, Colors.green),
            const SizedBox(width: 10),
            _buildStatCard('Gider', viewModel.totalExpense, Colors.red),
            const SizedBox(width: 10),
            _buildStatCard(
              'Net',
              viewModel.netBalance,
              viewModel.netBalance >= 0 ? Colors.blue : Colors.deepOrange,
            ),
          ],
        ),
        // GÜNCELLEME: Karşılaştırma kartı
        if (viewModel.expenseChangePercentage != null)
          _buildComparisonCard(viewModel),
      ],
    );
  }

  // YENİ: Karşılaştırma kartı
  Widget _buildComparisonCard(AnalysisViewModel viewModel) {
    String text = '';
    Color color = Colors.grey;
    IconData icon = Icons.remove;

    final double change = viewModel.expenseChangePercentage!;

    if (change > 0.05) {
      // %5'ten fazla artış
      text =
          "Giderleriniz önceki döneme göre %${(change * 100).toStringAsFixed(0)} arttı.";
      color = Colors.red;
      icon = Icons.arrow_upward;
    } else if (change < -0.05) {
      // %5'ten fazla azalış
      text =
          "Giderleriniz önceki döneme göre %${(-change * 100).toStringAsFixed(0)} azaldı.";
      color = Colors.green;
      icon = Icons.arrow_downward;
    } else {
      text = "Giderleriniz önceki döneme göre benzer seviyede.";
    }

    return Card(
      color: color.withOpacity(0.1),
      elevation: 0,
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, double amount, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                moneyFormat.format(amount),
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ÇİZGİ GRAFİK (AYLIK TREND)
  Widget _buildMonthlyLineChart(AnalysisViewModel viewModel) {
    final monthlyData = viewModel.getMonthlyTrendData();
    final maxVal = viewModel.maxMonthlyValue;

    if (monthlyData.isEmpty || maxVal == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("Yeterli tarihsel veri (son 6 ay) bulunamadı."),
        ),
      );
    }

    List<FlSpot> incomeSpots = [];
    List<FlSpot> expenseSpots = [];

    for (int i = 0; i < monthlyData.length; i++) {
      incomeSpots.add(FlSpot(i.toDouble(), monthlyData[i]['income']!));
      expenseSpots.add(FlSpot(i.toDouble(), monthlyData[i]['expense']!));
    }

    final monthLabels = monthlyData.map((e) {
      final date = DateTime(DateTime.now().year, e['month']!.toInt());
      return DateFormat('MMM', 'tr_TR').format(date); // 'tr_TR' eklendi
    }).toList();

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxVal,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxVal / 5,
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 &&
                      value.toInt() < monthLabels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        monthLabels[value.toInt()],
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return Container();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  // Y ekseninde büyük değerleri kısaltarak göster
                  if (value == 0 ||
                      (value > 0 &&
                          maxVal > 0 &&
                          value.toDouble() % (maxVal / 5).roundToDouble() ==
                              0)) {
                    String formattedValue = moneyFormat
                        .format(value)
                        .replaceAll('₺', '')
                        .replaceAll(',00', '');
                    // Değeri 'K' veya 'M' olarak kısalt
                    if (value >= 1000000) {
                      formattedValue =
                          '${(value / 1000000).toStringAsFixed(1)}M';
                    } else if (value >= 1000) {
                      formattedValue = '${(value / 1000).toStringAsFixed(0)}K';
                    }
                    return Text(
                      formattedValue,
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return Container();
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d), width: 1),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: incomeSpots,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withOpacity(0.1),
              ),
            ),
            LineChartBarData(
              spots: expenseSpots,
              isCurved: true,
              color: Colors.redAccent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.redAccent.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // PASTA GRAFİĞİ (HARCAMA DAĞILIMI)
  Widget _buildPieChart(AnalysisViewModel viewModel) {
    // GÜNCELLEME: 'Diğer' kategorisini de içerecek şekilde 'getTopExpenseData'yı çağır
    final topExpenseData = viewModel.getTopExpenseData(count: 5);

    if (topExpenseData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("Seçili dönemde harcama bulunmamaktadır."),
        ),
      );
    }

    const List<Color> chartColors = [
      Color(0xFF42A5F5), Color(0xFFFF7043), Color(0xFF66BB6A),
      Color(0xFFAB47BC),
      Color(0xFFFFCA28),
      Color(0xFF78909C), // 'Diğer' için renk
    ];

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              startDegreeOffset: -90,
              sections: topExpenseData.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                final color = chartColors[index % chartColors.length];

                return PieChartSectionData(
                  color: color,
                  value: data['amount'],
                  title: '${(data['percentage'] * 100).toStringAsFixed(1)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: topExpenseData.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            final color = chartColors[index % chartColors.length];

            // GÜNCELLEME: Kategori adı 'Diğer' ise _getCategoryName'i çağırma
            final categoryName = (data['category'] == 'Diğer')
                ? 'Diğer'
                : _getCategoryName(data['category']);

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  categoryName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
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

  // KATEGORİ LİSTESİ
  Widget _buildExpenseList(AnalysisViewModel viewModel) {
    final sortedExpenses = viewModel.expenseSummary.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedExpenses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("Seçili dönemde kategori bazlı gider bulunmamaktadır."),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedExpenses.length,
      itemBuilder: (context, index) {
        final item = sortedExpenses[index];
        final percentage = viewModel.totalExpense > 0
            ? (item.value / viewModel.totalExpense)
            : 0.0;
        final percentageText = (percentage * 100).toStringAsFixed(1);

        final categoryName = _getCategoryName(item.key);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      categoryName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    moneyFormat.format(item.value),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.redAccent,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$percentageText%',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      },
    );
  }
}
