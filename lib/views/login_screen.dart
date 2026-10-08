import 'dart:async';
import 'package:test_borsa/utils/feature_flags.dart';

import 'package:flutter/material.dart';
import 'verify_email_page.dart';
import '../services/user_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:test_borsa/views/home_page.dart';
import 'package:test_borsa/views/two_factor_verification_page.dart';
import '../view_model/user_view_model.dart';
import '../utils/error_handler.dart';
import 'forget_password_page.dart';
import 'widgets/ui/brand.dart';
import 'widgets/ui/ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  // 2FA için
  final bool _waiting2FA = false;
  String? _sessionToken;
  Timer? _pollingTimer;
  final int _remainingSeconds = 120;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  /*
  Future<void> _login() async {
    if (!mounted) return;

    if (_formKey.currentState!.validate()) {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);

      try {
        await userViewModel.login(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (!mounted) return;


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hoş geldiniz!'), backgroundColor: Colors.green),
        );
        await Future.delayed(Duration(milliseconds: 200));
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
*/
  Future<void> _login() async {
    if (!mounted) return;

    if (_formKey.currentState!.validate()) {
      // isLoading durumunu yönetmek için ViewModel'i burada da dinleyebiliriz.
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);

      try {
        // 1. ViewModel'deki login metodunu çağır ve dönen sonucu yakala.
        final loginResult = await userViewModel.login(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (!mounted) return;

        // 2. Dönen sonucu kontrol et: 2FA gerekli mi?
        if (loginResult['requires_2fa'] == true) {
          // Evet, 2FA gerekli.
          // Kullanıcıyı, session_token ile birlikte Onay Bekleme sayfasına yönlendir.
          final sessionToken = loginResult['session_token'];
          Navigator.push(
            context,
            MaterialPageRoute(
              // Bu sayfayı projenizde oluşturmanız gerekecek
              builder: (context) =>
                  TwoFactorVerificationPage(sessionToken: sessionToken),
            ),
          );
        } else {
          // Hayır, 2FA gerekli değil. Normal giriş başarılı oldu.
          // Kullanıcıyı ana sayfaya yönlendir.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hoş geldiniz!'),
              backgroundColor: Colors.green,
            ),
          );
          // Kısa bir gecikme, SnackBar'ın görünmesi için iyi olabilir.
          await Future.delayed(Duration(milliseconds: 200));
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/home');
        }
      } on EmailNotVerifiedException catch (e) {
        // Hesap var ama e-posta doğrulanmamış: sunucu yeni kod gönderdi
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VerifyEmailPage(email: e.email)),
        );
      } catch (e) {
        if (!mounted) return;

        // Hata durumunda kullanıcıya bilgi ver.
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final userViewModel = Provider.of<UserViewModel>(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: c.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Üst mavi alan
            GridPattern(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.page,
                    AppSpace.xl,
                    AppSpace.page,
                    36,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BrandMark(),
                      const SizedBox(height: 56),
                      Text(
                        'Paran cebinde,\nkontrol sende.',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: Colors.white, fontSize: 32),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Hesabına giriş yap.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Form
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpace.page,
                28,
                AppSpace.page,
                AppSpace.xl + bottomInset,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LabeledField(
                      label: 'E-posta',
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'ornek@eposta.com',
                          prefixIcon: Icon(Icons.mail_outline, size: 20),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'E-posta adresi gerekli';
                          }
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(value.trim())) {
                            return 'Geçerli bir e-posta adresi girin';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    LabeledField(
                      label: 'Şifre',
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) =>
                            userViewModel.isLoading ? null : _login(),
                        decoration: InputDecoration(
                          hintText: 'Şifren',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Şifreyi göster'
                                : 'Şifreyi gizle',
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        // Uzunluk kuralı şifre belirlenirken uygulanır; girişte
                        // eski (kısa) şifreli kullanıcıları engellememek için yok
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Şifre gerekli'
                            : null,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ForgotPasswordPage(),
                          ),
                        ),
                        child: const Text('Şifremi unuttum'),
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    AppButton(
                      label: 'Giriş yap',
                      loading: userViewModel.isLoading,
                      onPressed: _login,
                    ),

                    // Google ile Giriş (v1'de kapalı; bkz. feature_flags.dart)
                    if (kGoogleSignInEnabled) ...[
                      const SizedBox(height: AppSpace.md),
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            final GoogleSignInAccount? googleUser =
                                await _googleSignIn.signIn();
                            if (googleUser == null) return;
                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => HomePage()),
                            );
                          } catch (error) {
                            if (!context.mounted) return;
                            ErrorHandler.showErrorSnackBar(context, error);
                          }
                        },
                        icon: const Icon(Icons.g_mobiledata),
                        label: const Text('Google ile giriş yap'),
                      ),
                    ],

                    const SizedBox(height: AppSpace.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Hesabın yok mu? ',
                          style: TextStyle(color: c.textMuted),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/register'),
                          child: Text(
                            'Kayıt ol',
                            style: TextStyle(
                              color: c.text,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
