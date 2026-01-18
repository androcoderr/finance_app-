import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_borsa/views/profile_page.dart';
import 'package:test_borsa/views/two_factor_settings_page.dart';
import 'package:test_borsa/views/widgets/settings_widgets/about_page.dart';
import 'package:test_borsa/views/widgets/settings_widgets/build_listTile.dart';
import 'package:test_borsa/views/widgets/settings_widgets/legal_page.dart';
import 'package:url_launcher/url_launcher.dart';

// Gerekli ViewModel'ları import ediyoruz
import '../view_model/export_view_model.dart';
import '../view_model/setting_helper_methods.dart';
import '../view_model/settings_view_model.dart';
import '../utils/error_handler.dart';
import '../services/BaseService.dart';

// API adresi ve token alıcı (Hesap Silme için gerekli)
String get baseUrl => BaseService.baseUrl;

Future<void> _launchURL(String url) async {
  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Ayarlar'), elevation: 1),
      backgroundColor: colorScheme.surface,
      body: Consumer<SettingsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.state == SettingsState.loading) {
            return Center(child: CircularProgressIndicator());
          }
          if (viewModel.state == SettingsState.error) {
            return Center(child: Text("Hata: ${viewModel.errorMessage}"));
          }

          return ListView(
            children: [
              // HESAP BÖLÜMÜ
              _buildSectionTitle(context, 'Hesap'),
              buildListTile(
                context,
                title: 'Profil Bilgileri',
                subtitle: 'Ad, e-posta, şifre',
                icon: Icons.person_outline,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilePage()),
                  );
                },
              ),

              // GÜVENLİK BÖLÜMÜ
              _buildSectionTitle(context, 'Güvenlik'),
              buildListTile(
                context,
                title: 'İki Faktörlü Doğrulama',
                subtitle: 'Hesabınızı ekstra güvenlik katmanıyla koruyun',
                icon: Icons.security,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TwoFactorSettingsPage(),
                    ),
                  );
                },
              ),

              // VERİ VE GİZLİLİK BÖLÜMÜ
              _buildSectionTitle(context, 'Veri ve Gizlilik'),
              buildListTile(
                context,
                title: 'Verileri Dışa Aktar',
                subtitle: 'Finansal raporunuzu PDF olarak indirin',
                icon: Icons.download_outlined,
                onTap: () {
                  // Temizlenmiş ve ViewModel kullanan fonksiyon
                  _showExportDialog(context);
                },
              ),
              buildListTile(
                context,
                title: 'Hesabı Sil',
                subtitle: 'Tüm verileriniz kalıcı olarak silinecektir',
                icon: Icons.delete_forever_outlined,
                color: Colors.red,
                onTap: () {
                  // Tam ve çalışan hesap silme fonksiyonu
                  showDeleteAccountDialog(context);
                },
              ),

              // DESTEK VE GERİ BİLDİRİM BÖLÜMÜ
              _buildSectionTitle(context, 'Destek ve Geri Bildirim'),
              buildListTile(
                context,
                title: 'Geri Bildirim Gönder',
                subtitle: 'Önerilerinizi bizimle paylaşın',
                icon: Icons.feedback_outlined,
                onTap: () {
                  showFeedbackDialog(context);
                },
              ),
              buildListTile(
                context,
                title: 'Bizi Değerlendirin',
                subtitle: 'App Store / Play Store',
                icon: Icons.star_outline,
                onTap: () {
                  _launchURL('https://play.google.com/store');
                },
              ),

              // YASAL BÖLÜM
              _buildSectionTitle(context, 'Yasal'),
              buildListTile(
                context,
                title: 'Kullanım Koşulları',
                subtitle: 'Hizmet kullanım şartları',
                icon: Icons.description_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          LegalPage(title: 'Kullanım Koşulları'),
                    ),
                  );
                },
              ),
              buildListTile(
                context,
                title: 'Gizlilik Politikası',
                subtitle: 'Verilerinizi nasıl koruyoruz',
                icon: Icons.privacy_tip_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          LegalPage(title: 'Gizlilik Politikası'),
                    ),
                  );
                },
              ),
              buildListTile(
                context,
                title: 'Açık Kaynak Lisansları',
                subtitle: 'Kullanılan kütüphaneler',
                icon: Icons.code,
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: 'Test Borsa',
                    applicationVersion: '1.0.0',
                  );
                },
              ),

              // HAKKINDA BÖLÜMÜ
              _buildSectionTitle(context, 'Hakkında'),
              buildListTile(
                context,
                title: 'Hakkımızda',
                subtitle: 'Misyon ve vizyonumuz',
                icon: Icons.info_outline,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AboutPage()),
                  );
                },
              ),
              buildListTile(
                context,
                title: 'İletişim',
                subtitle: 'Bizimle iletişime geçin',
                icon: Icons.contact_support_outlined,
                onTap: () {
                  showContactDialog(context);
                },
              ),
              buildListTile(
                context,
                title: 'Uygulama Sürümü',
                subtitle: '1.0.0 (Build 100)',
                icon: Icons.smartphone,
              ),

              SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Padding _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ====================================================================
// BU SAYFAYA AİT TÜM YARDIMCI METOTLAR VE DİYALOGLAR
// ====================================================================

// --- PDF Dışa Aktarma (ViewModel Kullanarak) ---
void _showExportDialog(BuildContext context) {
  final exportViewModel = Provider.of<ExportViewModel>(context, listen: false);

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Raporu Dışa Aktar'),
      content: Text(
        'Aylık finansal raporunuz PDF olarak hazırlanıp açılacaktır. Onaylıyor musunuz?',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('İptal')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Rapor hazırlanıyor, lütfen bekleyin...')),
            );
            await exportViewModel.generateAndExportReport(context);
            if (context.mounted) {
              if (exportViewModel.state == ExportState.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Rapor başarıyla oluşturuldu!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (exportViewModel.state == ExportState.error) {
                ErrorHandler.showErrorSnackBar(
                  context,
                  exportViewModel.errorMessage,
                );
              }
            }
          },
          child: Text('Dışa Aktar'),
        ),
      ],
    ),
  );
}
