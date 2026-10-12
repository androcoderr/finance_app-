import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

import 'widgets/ui/brand.dart';
import 'widgets/ui/ui.dart';

/// Kapatılamayan "güncelleme gerekli" ekranı (geri tuşu uygulamayı kapatır)
class ForceUpdatePage extends StatefulWidget {
  final String? message;
  final String storeUrl;
  const ForceUpdatePage({super.key, this.message, required this.storeUrl});

  /// Play'den kurulduysa uygulama içi güncelleme; değilse (emülatör, sideload)
  /// ya da hata olursa mağaza sayfası açılır
  static Future<void> update(String storeUrl) async {
    // Uygulama içi güncelleme yalnızca Android'de (Play); iOS'ta App Store açılır
    if (Platform.isAndroid) {
      try {
        final info = await InAppUpdate.checkForUpdate();
        if (info.updateAvailability == UpdateAvailability.updateAvailable) {
          await InAppUpdate.performImmediateUpdate();
          return;
        }
      } catch (_) {}
    }
    await launchUrl(Uri.parse(storeUrl), mode: LaunchMode.externalApplication);
  }

  @override
  State<ForceUpdatePage> createState() => _ForceUpdatePageState();
}

class _ForceUpdatePageState extends State<ForceUpdatePage> {
  bool _busy = false;

  Future<void> _update() async {
    setState(() => _busy = true);
    await ForceUpdatePage.update(widget.storeUrl);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop(); // Geri tuşu: uygulamayı kapat
      },
      child: Scaffold(
        body: GridPattern(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  const Center(child: BrandMark(size: 72)),
                  const SizedBox(height: 28),
                  const Text(
                    'Güncelleme gerekli',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.message ??
                        'Uygulamanın yeni bir sürümü var. Devam etmek için lütfen güncelleyin.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xDDFFFFFF), fontSize: 15, height: 1.45),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.brandBlue,
                    ),
                    onPressed: _busy ? null : _update,
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.system_update_alt),
                              SizedBox(width: 10),
                              Text('Güncelle'),
                            ],
                          ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
