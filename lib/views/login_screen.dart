
import 'package:flutter/material.dart';
import 'verify_email_page.dart';
import '../services/user_service.dart';
import 'package:provider/provider.dart';
import '../view_model/user_view_model.dart';
import '../utils/error_handler.dart';
import 'forget_password_page.dart';
import 'widgets/ui/brand.dart';
import 'widgets/ui/ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;


  void _showWelcome() {
    final name = context.read<UserViewModel>().currentUser?.name.trim().split(' ').first;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.waving_hand_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name == null || name.isEmpty ? 'Hoş geldin!' : 'Hoş geldin, $name!',
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!mounted || !_formKey.currentState!.validate()) return;
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    try {
      await userViewModel.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      _showWelcome();
      Navigator.pushReplacementNamed(context, '/home');
    } on EmailNotVerifiedException catch (e) {
      // Hesap var ama e-posta doğrulanmamış: sunucu yeni kod gönderdi
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyEmailPage(
            email: e.email,
            password: _passwordController.text,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final userViewModel = Provider.of<UserViewModel>(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          SingleChildScrollView(
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
                      const BrandMark(size: 60),
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
          // Kaydırınca içerik saat/pil şeridinin altına girmesin
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topInset,
            child: const ColoredBox(color: AppColors.brandBlue),
          ),
        ],
      ),
    );
  }
}
