import 'package:flutter/material.dart';
import '../services/forget_password_service.dart';
import '../utils/error_handler.dart';
import 'widgets/ui/ui.dart';

class ResetPasswordPage extends StatefulWidget {
  final String token;

  const ResetPasswordPage({super.key, required this.token});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isTokenValid = false;
  String? _email;

  @override
  void initState() {
    super.initState();
    _verifyToken();
  }

  Future<void> _verifyToken() async {
    final result = await PasswordResetService.verifyToken(widget.token);

    if (mounted) {
      setState(() {
        _isTokenValid = result['valid'] ?? false;
        _email = result['email'];
      });

      if (!_isTokenValid) {
        _showError('Token geçersiz veya süresi dolmuş');
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final result = await PasswordResetService.resetPassword(
        widget.token,
        _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (result['success']) {
        _showSuccessDialog();
      } else {
        _showError(result['error']);
      }
    }
  }

  bool _done = false;

  void _showSuccessDialog() => setState(() => _done = true);

  void _showError(String message) => ErrorHandler.showErrorSnackBar(context, message);

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    if (_done) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.page),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: ToneIcon(icon: Icons.check, tone: Tone.green, size: 80)),
                const SizedBox(height: AppSpace.xl),
                Text(
                  'Şifren güncellendi',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Artık yeni şifrenle giriş yapabilirsin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textMuted),
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Giriş yap',
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (_) => false,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
              const Align(
                alignment: Alignment.centerLeft,
                child: ToneIcon(icon: Icons.lock_reset, tone: Tone.blue, size: 64),
              ),
              const SizedBox(height: AppSpace.xl),
              Text(
                'Yeni şifre\nbelirle',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 34),
              ),
              const SizedBox(height: 10),
              if (_email != null)
                Text.rich(
                  TextSpan(
                    style: TextStyle(color: c.textMuted, fontSize: 15),
                    children: [
                      TextSpan(
                        text: _email,
                        style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' hesabı için'),
                    ],
                  ),
                )
              else if (!_isTokenValid)
                Text(
                  'Kod doğrulanıyor…',
                  style: TextStyle(color: c.textMuted, fontSize: 15),
                ),
              const SizedBox(height: 28),
              LabeledField(
                label: 'Yeni şifre',
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: _isTokenValid,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    hintText: 'En az 8 karakter',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword ? 'Şifreyi göster' : 'Şifreyi gizle',
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Şifre gerekli';
                    if (v.length < 8) return 'Şifre en az 8 karakter olmalı';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              LabeledField(
                label: 'Yeni şifre tekrar',
                child: TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  enabled: _isTokenValid,
                  decoration: InputDecoration(
                    hintText: 'Şifreni tekrar yaz',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      tooltip: _obscureConfirmPassword ? 'Şifreyi göster' : 'Şifreyi gizle',
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                  ),
                  validator: (v) =>
                      v != _passwordController.text ? 'Şifreler eşleşmiyor' : null,
                ),
              ),
              const SizedBox(height: 28),
              AppButton(
                label: 'Şifreyi güncelle',
                icon: Icons.check,
                loading: _isLoading,
                onPressed: _isTokenValid ? _resetPassword : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
