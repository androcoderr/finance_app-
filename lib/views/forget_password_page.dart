import 'dart:async';

import 'package:flutter/material.dart';

import '../services/forget_password_service.dart';
import '../utils/error_handler.dart';
import 'widgets/ui/ui.dart';

/// Şifre sıfırlama bağlantısı isteme. E-postadaki bağlantı web'de yeni şifre
/// formunu açar; açılmazsa e-postadaki kod buraya yapıştırılabilir.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  static const _cooldown = 60;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  bool _showCodeEntry = false;
  int _secondsLeft = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _cooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate() || _secondsLeft > 0) return;
    setState(() => _isLoading = true);
    final result = await PasswordResetService.sendResetEmail(
      _emailController.text.trim().toLowerCase(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result['success']) {
      setState(() => _emailSent = true);
      _startCooldown();
    } else {
      ErrorHandler.showErrorSnackBar(context, result['error']);
    }
  }

  void _continueWithCode() {
    final token = _tokenController.text.trim();
    if (token.length < 20) {
      ErrorHandler.showErrorSnackBar(context, 'E-postadaki kodun tamamını yapıştır');
      return;
    }
    Navigator.pushNamed(context, '/reset-password', arguments: token);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final countdown =
        '${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.xl),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const ToneIcon(icon: Icons.mail_outline, tone: Tone.blue, size: 68),
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.key, size: 16, color: c.onPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              Text(
                'Şifreni mi\nunuttun?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 34),
              ),
              const SizedBox(height: 10),
              Text(
                'Kayıtlı e-postanı gir, şifreni yenilemen için bir bağlantı gönderelim.',
                style: TextStyle(color: c.textMuted, fontSize: 15, height: 1.45),
              ),
              const SizedBox(height: 28),
              LabeledField(
                label: 'E-posta',
                child: TextFormField(
                  controller: _emailController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    hintText: 'ornek@eposta.com',
                    prefixIcon: Icon(Icons.mail_outline, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'E-posta adresi gerekli';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                      return 'Geçerli bir e-posta adresi gir';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              AppButton(
                label: _emailSent ? 'Tekrar gönder' : 'Bağlantı gönder',
                icon: Icons.send_outlined,
                loading: _isLoading,
                onPressed: _secondsLeft > 0 ? null : _sendResetEmail,
              ),
              if (_emailSent) ...[
                const SizedBox(height: AppSpace.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  decoration: BoxDecoration(
                    color: c.incomeSoft,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c.income,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bağlantı gönderildi',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bu adres kayıtlıysa e-postana bir bağlantı gönderdik. '
                              '30 dakika geçerli. Spam klasörüne de bak.'
                              '${_secondsLeft > 0 ? ' Gelmediyse $countdown sonra tekrar gönderebilirsin.' : ''}',
                              style: TextStyle(color: c.text, height: 1.4, fontSize: 13.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                if (!_showCodeEntry)
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _showCodeEntry = true),
                      child: const Text('Bağlantı açılmıyor mu? Kodla devam et'),
                    ),
                  )
                else ...[
                  LabeledField(
                    label: 'E-postadaki sıfırlama kodu',
                    child: TextField(
                      controller: _tokenController,
                      maxLines: 3,
                      minLines: 2,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Kodu buraya yapıştır',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  OutlinedButton(
                    onPressed: _continueWithCode,
                    child: const Text('Kodla devam et'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
