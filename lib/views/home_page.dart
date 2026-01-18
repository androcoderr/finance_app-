import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_borsa/views/add_transaction_page.dart';
import 'package:test_borsa/views/widgets/home_widget/build_assets_section.dart';
import 'package:test_borsa/views/widgets/home_widget/build_bottom_navigation_bar.dart';
import 'package:test_borsa/views/widgets/home_widget/build_charts_section.dart';
import 'package:test_borsa/views/widgets/home_widget/build_drawer.dart';
import 'package:test_borsa/views/widgets/home_widget/build_goal_section.dart';
import 'package:test_borsa/views/widgets/home_widget/build_welcome_section.dart';
import 'package:test_borsa/views/widgets/home_widget/intro_widget.dart';
import 'package:test_borsa/views/widgets/notification_icon.dart';
import '../view_model/home_view_model.dart';
import '../view_model/user_view_model.dart';
import 'finance_screen.dart';
import 'widgets/home_widget/build_recent_transaction.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<HomeViewModel, UserViewModel>(
      builder: (context, homeViewModel, userViewModel, child) {
        // Eğer kullanıcı giriş yapmamışsa login sayfasına yönlendir
        if (!userViewModel.isLoggedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          appBar: _buildAppBar(context),
          endDrawer: DrawerWidget(viewModel: homeViewModel),
          body: _buildBody(homeViewModel, context),
          bottomNavigationBar: buildBottomNavigationBar(context, homeViewModel),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Finans Cepte',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      backgroundColor: Colors.blue[600],
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false, // Sol taraftaki back button'ı kaldır
      actions: [
        NotificationIconWithBadge(),
        // Bildirim ikonu
        /*IconButton(
          icon: Icon(Icons.notifications_outlined),
          onPressed: () {
            Navigator.pushNamed(context, '/notifications');
          },
        ),*/
        // Menü ikonu
        Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(HomeViewModel viewModel, BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Verileri yenile
        await viewModel.refresh();
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hoş geldin bölümü
            buildWelcomeSection(viewModel),
            SizedBox(height: 20),

            // Varlıklar bölümü
            const IntroSliderSection(),
            _buildSectionTitle('Varlıklarım'),
            SizedBox(height: 12),
            buildAssetsSection(viewModel, context),
            SizedBox(height: 24),

            // Grafik bölümü
            _buildSectionTitle('Bu Ay'),
            SizedBox(height: 12),
            buildChartsSection(viewModel, context),
            SizedBox(height: 24),

            // Hedefler bölümü
            if (viewModel.hasGoals) ...[
              _buildSectionTitle('Hedeflerim'),
              SizedBox(height: 12),
              buildGoalsSection(viewModel),
              SizedBox(height: 24),
            ],
            SizedBox(height: 12),
            buildRecentTransactions(viewModel, context),

            // Alt navigasyon için minimum boşluk
            SizedBox(height: 16), // 100 yerine 16, overflow'u önlemek için
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required HomeViewModel viewModel,
    bool isSpecial = false,
  }) {
    final bool isSelected = viewModel.selectedIndex == index;

    return GestureDetector(
      onTap: () => _handleNavigation(context, index, viewModel),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: isSpecial ? EdgeInsets.all(8) : EdgeInsets.all(4),
              decoration: isSpecial
                  ? BoxDecoration(
                      color: isSelected ? Colors.blue[700] : Colors.blue[600],
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSpecial
                    ? Colors.white
                    : isSelected
                    ? Colors.blue[600]
                    : Colors.grey[400],
                size: isSpecial ? 24 : 26,
              ),
            ),
            // SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.blue[600] : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(
    BuildContext context,
    int index,
    HomeViewModel viewModel,
  ) {
    viewModel.onBottomNavTap(index);

    switch (index) {
      case 0:
        // Ana Sayfa - zaten buradayız
        break;
      case 1:
        // İşlem Ekle
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddTransactionPage()),
        ).then((_) {
          // Sayfa dönüşünde verileri yenile
          viewModel.refresh();
          // Sayfa dönüşünde index'i sıfırla
          viewModel.onBottomNavTap(0);
        });
        break;
      case 2:
        // Döviz Sayfası
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FinanceScreen()),
        ).then((_) {
          // Sayfa dönüşünde index'i sıfırla
          viewModel.onBottomNavTap(0);
        });
        break;
    }
  }
}
