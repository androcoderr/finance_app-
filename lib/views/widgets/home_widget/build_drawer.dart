import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:test_borsa/views/goal_page.dart';
import '../../../view_model/home_view_model.dart';
import '../../../view_model/user_view_model.dart';
import '../../analysis_screen.dart';
import '../../bill_screen.dart';
import '../../login_screen.dart';
import '../../recurring_transaction_view.dart';
import '../../settings_page.dart';
import '../../shopping_list_page.dart';
import '../theme_provider.dart';

class DrawerWidget extends StatefulWidget {
  final HomeViewModel viewModel;

  const DrawerWidget({super.key, required this.viewModel});

  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

Future<void> _shareApp(BuildContext context) async {
  // Uygulamanızın indirme linkini buraya yazın.
  // Henüz linkiniz yoksa geçici bir link kullanabilirsiniz.
  const String appLink =
      "https://play.google.com/store/apps/details?id=com.finanscepte.app";

  // Paylaşılacak olan davet mesajını oluşturun.
  // Uygulamanızın en iyi özelliklerini vurgulayın!
  const String davetMesaji =
      "Selam, harcamalarımı ve bütçemi yönetmek için bu harika uygulamayı kullanıyorum. "
      "Hatta anormal harcamalarımı bile tespit ediyor! Bence sen de denemelisin:\n\n"
      "$appLink";

  // Paylaşım menüsünü açan kod
  Share.share(davetMesaji);
}

Future<void> _logout(BuildContext context) async {
  try {
    // Token'ları, bellekteki kullanıcıyı ve cihazdaki kullanıcı verilerini temizle
    // (tema gibi cihaz tercihleri korunur)
    await context.read<UserViewModel>().logout();
    if (!context.mounted) return;

    // Login sayfasına yönlendir ve tüm stack'i temizle
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => LoginScreen(),
      ), // Login sayfanızın adı
      (route) => false, // Tüm önceki sayfaları temizle
    );

    // Başarı mesajı
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Çıkış yapıldı'), backgroundColor: Colors.green),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Çıkış yapılırken hata: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class _DrawerWidgetState extends State<DrawerWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue[600]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 30, color: Colors.blue[600]),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.viewModel.currentUser!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.viewModel.currentUser!.email,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.flag, color: Colors.blue[600]),
            title: const Text('Hedeflerim'),
            trailing: widget.viewModel.goals.isNotEmpty
                ? CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.green,
                    child: Text(
                      '${widget.viewModel.goals.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      GoalsPage(userId: widget.viewModel.userId as String),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.receipt, color: Colors.blue[600]),
            title: const Text('Faturalarım'), //BillsPage
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BillsPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.bar_chart, color: Colors.blue[600]),
            title: const Text('Raporlar'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AnalysisScreen()),
              );
            },
          ),
          /*
          ListTile(
            leading: Icon(Icons.person, color: Colors.blue[600]),
            title: const Text('Kişi Bilgileri'),
            onTap: () {
              // Navigator.pop(context);
            },
          ),*/
          ListTile(
            leading: Icon(Icons.list, color: Colors.blue[600]),
            title: const Text('Alış-Veriş Listesi'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ShoppingListPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.repartition, color: Colors.blue[600]),
            title: const Text('Tekrarlayan işlemler'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecurringTransactionsPage(
                    userId: widget.viewModel.userId as String,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.mobile_friendly, color: Colors.blue[600]),
            title: const Text('Arkadaşlarına tavsiye et'),
            onTap: () async => await _shareApp(context),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Karanlık mod'),
            value: themeProvider.isDarkMode,
            // ThemeProvider tercihi kendisi kaydeder
            onChanged: (value) => context.read<ThemeProvider>().toggleTheme(value),
            secondary: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
            activeThumbColor: Colors.blue,
            activeTrackColor: Colors.blue.shade200,
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.shade400,
          ),
          SwitchListTile(
            title: const Text('Tutarı gizle'),
            value: widget.viewModel.secretMoney,
            onChanged: (value) async {
              await widget.viewModel.setSecretMoney(value);
            },
            secondary: Icon(
              widget.viewModel.secretMoney
                  ? Icons.visibility_off
                  : Icons.visibility,
            ),
            activeThumbColor: Colors.blue,
            activeTrackColor: Colors.blue.shade200,
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.shade400,
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.settings, color: Colors.grey[600]),
            title: const Text('Ayarlar'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.grey[600]),
            title: const Text('Çıkış Yap'),
            onTap: () {
              Navigator.pop(context); // Drawer'ı kapat
              _logout(context); // Logout işlemini yap
            },
          ),
        ],
      ),
    );
  }
}
