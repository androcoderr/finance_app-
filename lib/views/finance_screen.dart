import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/finance_piyasa_widget/buidErrorWidget.dart';
import '../view_model/finance_view_model.dart';
import '../models/finance_model.dart';
import 'widgets/finance_piyasa_widget/buildStatCard.dart';
import 'widgets/finance_piyasa_widget/buildLoadingWidget.dart';
import 'widgets/finance_piyasa_widget/buildSortButton.dart';
import 'widgets/finance_piyasa_widget/buildDetailRow.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  _FinanceScreenState createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late FinanceViewModel _viewModel;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _viewModel = Provider.of<FinanceViewModel>(context, listen: false);

    // ✅ DÜZELTME: initState'te await kullanma!
    // Build tamamlandıktan sonra çalıştır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    await _viewModel.loadDataWithCache();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Consumer<FinanceViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              _buildStatsHeader(viewModel),
              _buildSearchAndFilters(viewModel),
              _buildTabContent(viewModel),
            ],
          );
        },
      ),
      floatingActionButton: buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('Döviz Kurları'),
      backgroundColor: Colors.blue.shade700,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        Consumer<FinanceViewModel>(
          builder: (context, viewModel, child) {
            return IconButton(
              icon: viewModel.isRefreshing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.refresh),
              onPressed: viewModel.isRefreshing ? null : viewModel.refreshData,
              tooltip: 'Yenile',
            );
          },
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuSelection,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'auto_refresh',
              child: Text('Otomatik Yenileme'),
            ),
            PopupMenuItem(
              value: 'clear_favorites',
              child: Text('Favorileri Temizle'),
            ),
            PopupMenuItem(value: 'debug_info', child: Text('Debug Bilgisi')),
          ],
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: [
          Tab(text: 'Tümü', icon: Icon(Icons.list, size: 16)),
          Tab(text: 'Döviz', icon: Icon(Icons.attach_money, size: 16)),
          Tab(text: 'Altın', icon: Icon(Icons.star, size: 16)),
          Tab(text: 'Kripto', icon: Icon(Icons.currency_bitcoin, size: 16)),
          Tab(text: 'BIST', icon: Icon(Icons.trending_up, size: 16)),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(FinanceViewModel viewModel) {
    if (viewModel.isLoading) {
      return Container(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      );
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              buildStatCard(
                'Toplam',
                '${viewModel.financeData.length}',
                Icons.list,
              ),
              buildStatCard(
                'Yükselenler',
                '${viewModel.positiveCount}',
                Icons.trending_up,
                Colors.green,
              ),
              buildStatCard(
                'Düşenler',
                '${viewModel.negativeCount}',
                Icons.trending_down,
                Colors.red,
              ),
              buildStatCard(
                'Favoriler',
                '${viewModel.favorites.length}',
                Icons.favorite,
                Colors.pink,
              ),
            ],
          ),
          if (viewModel.lastUpdateTime.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              'Son Güncelleme: ${viewModel.lastUpdateTime}',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(FinanceViewModel viewModel) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: viewModel.updateSearchQuery,
            decoration: InputDecoration(
              hintText: 'Ara...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: viewModel.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        viewModel.clearSearch();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
          ),
          SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                buildSortButton('İsim', SortType.name, viewModel),
                buildSortButton('Fiyat', SortType.price, viewModel),
                buildSortButton('Değişim', SortType.change, viewModel),
                buildSortButton('Tarih', SortType.date, viewModel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(FinanceViewModel viewModel) {
    if (viewModel.hasError) {
      return Expanded(child: buildErrorWidget(viewModel));
    }

    if (viewModel.isLoading) {
      return Expanded(child: buildLoadingWidget());
    }

    return Expanded(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildDataList(viewModel.filteredData, viewModel),
          _buildDataList(viewModel.getCurrencyData(), viewModel),
          _buildDataList(viewModel.getTurkishGoldData(), viewModel),
          _buildDataList(viewModel.getCryptoData(), viewModel),
          _buildDataList(viewModel.getBISTData(), viewModel),
        ],
      ),
    );
  }

  Widget _buildDataList(List<FinanceModel> data, FinanceViewModel viewModel) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Veri bulunamadı',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            if (viewModel.searchQuery.isNotEmpty)
              Text(
                '"${viewModel.searchQuery}" için sonuç yok',
                style: TextStyle(color: Colors.grey.shade600),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.refreshData,
      child: ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];
          return _buildFinanceCard(item, viewModel);
        },
      ),
    );
  }

  Widget _buildFinanceCard(FinanceModel item, FinanceViewModel viewModel) {
    bool isFavorite = viewModel.isFavorite(item.name);
    Color changeColor = item.change > 0
        ? Colors.green
        : item.change < 0
        ? Colors.red
        : Colors.grey;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: changeColor.withOpacity(0.1),
          child: Text(item.symbol, style: TextStyle(fontSize: 18)),
        ),
        title: Text(
          item.name,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.price.toStringAsFixed(2)} ${item.currency}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            SizedBox(height: 2),
            Text(
              'Güncelleme: ${_formatTime(item.lastUpdate)}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: changeColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${item.change > 0 ? '+' : ''}${item.change.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.grey,
              ),
              onPressed: () => viewModel.toggleFavorite(item.name),
            ),
          ],
        ),
        onTap: () => _showDetailDialog(item),
      ),
    );
  }

  Widget? buildFloatingActionButton() {
    return Consumer<FinanceViewModel>(
      builder: (context, viewModel, child) {
        return FloatingActionButton(
          onPressed: () => _showQuickActionsDialog(viewModel),
          backgroundColor: Colors.blue.shade700,
          child: Icon(Icons.more_vert),
        );
      },
    );
  }

  void _showQuickActionsDialog(FinanceViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hızlı İşlemler'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.favorite),
              title: Text('Favorileri Göster'),
              subtitle: Text('${viewModel.favorites.length} favori'),
              onTap: () {
                Navigator.pop(context);
                _showFavoritesDialog(viewModel);
              },
            ),
            ListTile(
              leading: Icon(Icons.trending_up),
              title: Text('En Çok Yükselenler'),
              onTap: () {
                Navigator.pop(context);
                _showTopGainersDialog(viewModel);
              },
            ),
            ListTile(
              leading: Icon(Icons.trending_down),
              title: Text('En Çok Düşenler'),
              onTap: () {
                Navigator.pop(context);
                _showTopLosersDialog(viewModel);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(FinanceModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(item.symbol, style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Expanded(child: Text(item.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildDetailRow(
              'Fiyat',
              '${item.price.toStringAsFixed(2)} ${item.currency}',
            ),
            buildDetailRow(
              'Değişim',
              '${item.change > 0 ? '+' : ''}${item.change.toStringAsFixed(2)}',
            ),
            buildDetailRow(
              'Değişim %',
              '${item.changePercentage.toStringAsFixed(2)}%',
            ),
            buildDetailRow('Son Güncelleme', _formatTime(item.lastUpdate)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showFavoritesDialog(FinanceViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Favoriler'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: viewModel.favoriteItems.isEmpty
              ? Center(child: Text('Henüz favori eklemediniz'))
              : ListView.builder(
                  itemCount: viewModel.favoriteItems.length,
                  itemBuilder: (context, index) {
                    final item = viewModel.favoriteItems[index];
                    return ListTile(
                      leading: Text(item.symbol),
                      title: Text(item.name),
                      subtitle: Text(
                        '${item.price.toStringAsFixed(2)} ${item.currency}',
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => viewModel.toggleFavorite(item.name),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showTopGainersDialog(FinanceViewModel viewModel) {
    final topGainers = viewModel.getTopGainers();
    _showTopMoversDialog('En Çok Yükselenler', topGainers);
  }

  void _showTopLosersDialog(FinanceViewModel viewModel) {
    final topLosers = viewModel.getTopLosers();
    _showTopMoversDialog('En Çok Düşenler', topLosers);
  }

  void _showTopMoversDialog(String title, List<FinanceModel> items) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: Text(item.symbol),
                title: Text(item.name),
                subtitle: Text(
                  '${item.price.toStringAsFixed(2)} ${item.currency}',
                ),
                trailing: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.change > 0 ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${item.change > 0 ? '+' : ''}${item.change.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  void _handleMenuSelection(String value) {
    final viewModel = Provider.of<FinanceViewModel>(context, listen: false);

    switch (value) {
      case 'auto_refresh':
        if (viewModel.autoRefreshEnabled) {
          viewModel.disableAutoRefresh();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Otomatik yenileme kapatıldı')),
          );
        } else {
          viewModel.enableAutoRefresh();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Otomatik yenileme açıldı')));
        }
        break;
      case 'clear_favorites':
        viewModel.clearFavorites();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Favoriler temizlendi')));
        break;
      case 'debug_info':
        viewModel.printDebugInfo();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Debug bilgisi konsola yazdırıldı')),
        );
        break;
    }
  }
}
