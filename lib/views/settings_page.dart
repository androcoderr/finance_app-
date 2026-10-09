import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/app_info.dart';
import '../utils/error_handler.dart';
import '../utils/feature_flags.dart';
import '../view_model/export_view_model.dart';
import '../view_model/home_view_model.dart';
import '../view_model/setting_helper_methods.dart';
import '../view_model/user_view_model.dart';
import 'login_screen.dart';
import 'profile_page.dart';
import 'two_factor_settings_page.dart';
import 'widgets/settings_widgets/legal_page.dart';
import 'widgets/theme_provider.dart';
import 'widgets/ui/brand.dart';
import 'widgets/ui/ui.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _export(BuildContext context) async {
    final vm = context.read<ExportViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Rapor hazırlanıyor…')));
    await vm.generateAndExportReport(context);
    if (!context.mounted) return;
    if (vm.state == ExportState.error) {
      ErrorHandler.showErrorSnackBar(context, vm.errorMessage);
    }
  }

  Future<void> _mailSupport(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: kSupportEmail,
      queryParameters: {'subject': '$kAppName geri bildirim (v$kAppVersion)'},
    );
    if (!await launchUrl(uri) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('E-posta uygulaması açılamadı. Bize $kSupportEmail adresinden ulaşabilirsin.')),
      );
    }
  }

  void _shareApp() {
    SharePlus.instance.share(ShareParams(
      text: 'Harcamalarımı, faturalarımı ve birikim hedeflerimi $kAppName ile '
          'takip ediyorum. Sen de dene:\n\n$kPlayStoreUrl',
    ));
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış yap'),
        content: const Text('Hesabından çıkış yapmak istediğine emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Çıkış yap')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<UserViewModel>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (_) => false,
    );
  }

  void _open(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final user = context.watch<UserViewModel>().currentUser;
    final theme = context.watch<ThemeProvider>();
    final home = context.watch<HomeViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.xl),
        children: [
          // Profil kartı
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: GridPattern(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _open(context, ProfilePage()),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.lg),
                    child: Row(
                      children: [
                        InitialsAvatar(
                          name: user?.name,
                          size: 52,
                          background: Colors.white,
                          foreground: AppColors.brandBlue,
                        ),
                        const SizedBox(width: AppSpace.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                user?.email ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Color(0xCCFFFFFF)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          _Group(title: 'Görünüm', children: [
            _Tile(
              icon: Icons.dark_mode_outlined,
              tone: Tone.purple,
              title: 'Karanlık mod',
              trailing: Switch(value: theme.isDarkMode, onChanged: theme.toggleTheme),
              onTap: () => theme.toggleTheme(!theme.isDarkMode),
            ),
            _Tile(
              icon: Icons.visibility_off_outlined,
              tone: Tone.teal,
              title: 'Tutarları gizle',
              subtitle: 'Ana sayfadaki tutarlar •••• olarak görünür',
              trailing: Switch(value: home.secretMoney, onChanged: home.setSecretMoney),
              onTap: () => home.setSecretMoney(!home.secretMoney),
            ),
          ]),

          _Group(title: 'Hesap', children: [
            _Tile(
              icon: Icons.person_outline,
              tone: Tone.blue,
              title: 'Profil ve şifre',
              subtitle: 'Ad, e-posta, şifre değiştir',
              onTap: () => _open(context, ProfilePage()),
            ),
            if (kTwoFactorEnabled)
              _Tile(
                icon: Icons.verified_user_outlined,
                tone: Tone.green,
                title: 'İki aşamalı doğrulama',
                onTap: () => _open(context, TwoFactorSettingsPage()),
              ),
          ]),

          _Group(title: 'Veriler', children: [
            _Tile(
              icon: Icons.picture_as_pdf_outlined,
              tone: Tone.orange,
              title: 'Raporu PDF olarak paylaş',
              subtitle: 'Bu ayın özeti, trend ve kategoriler',
              onTap: () => _export(context),
            ),
            _Tile(
              icon: Icons.delete_outline,
              tone: Tone.red,
              title: 'Hesabı sil',
              titleColor: c.expense,
              subtitle: 'Tüm verilerin kalıcı olarak silinir',
              onTap: () => showDeleteAccountDialog(context),
            ),
          ]),

          _Group(title: 'Destek', children: [
            _Tile(
              icon: Icons.mail_outline,
              tone: Tone.blue,
              title: 'Bize yaz',
              subtitle: 'Öneri, hata bildirimi, soru',
              onTap: () => _mailSupport(context),
            ),
            _Tile(
              icon: Icons.star_outline,
              tone: Tone.yellow,
              title: 'Uygulamayı değerlendir',
              onTap: () => launchUrl(Uri.parse(kPlayStoreUrl)),
            ),
            _Tile(
              icon: Icons.card_giftcard_outlined,
              tone: Tone.pink,
              title: 'Arkadaşına tavsiye et',
              onTap: _shareApp,
            ),
          ]),

          _Group(title: 'Yasal', children: [
            _Tile(
              icon: Icons.description_outlined,
              tone: Tone.grey,
              title: 'Kullanım koşulları',
              onTap: () => _open(context, LegalPage(title: 'Kullanım Koşulları')),
            ),
            _Tile(
              icon: Icons.privacy_tip_outlined,
              tone: Tone.grey,
              title: 'Gizlilik politikası',
              onTap: () => _open(context, LegalPage(title: 'Gizlilik Politikası')),
            ),
            _Tile(
              icon: Icons.code,
              tone: Tone.grey,
              title: 'Açık kaynak lisansları',
              onTap: () => showLicensePage(
                context: context,
                applicationName: kAppName,
                applicationVersion: kAppVersion,
              ),
            ),
          ]),

          const SizedBox(height: AppSpace.xl),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: c.expense,
              side: BorderSide(color: c.expense.withValues(alpha: 0.35)),
            ),
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Çıkış yap'),
          ),
          const SizedBox(height: AppSpace.lg),
          Center(
            child: Text(
              '$kAppName · v$kAppVersion',
              style: TextStyle(color: c.textFaint, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Group({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, AppSpace.xl, 0, AppSpace.sm),
          child: Overline(title),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Divider(height: 1, indent: 62, color: c.border),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Tone tone;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _Tile({
    required this.icon,
    required this.tone,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            ToneIcon(icon: icon, tone: tone, size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? c.text,
                    ),
                  ),
                  if (subtitle != null)
                    Text(subtitle!, style: TextStyle(color: c.textMuted, fontSize: 12.5)),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right, color: c.textFaint),
          ],
        ),
      ),
    );
  }
}
