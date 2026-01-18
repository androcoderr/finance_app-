import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:test_borsa/views/home_page.dart';
import 'package:test_borsa/views/two_factor_verification_page.dart';
import '../view_model/user_view_model.dart';
import '../utils/error_handler.dart';
import 'forget_password_page.dart';

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
          Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (e) {
        if (!mounted) return;

        // Hata durumunda kullanıcıya bilgi ver.
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 60),
              Icon(Icons.account_circle, size: 80, color: Colors.blue),
              SizedBox(height: 20),
              Text(
                'Giriş Yap',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Hesabınıza giriş yapın',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'E-mail adresi gerekli';
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Geçerli bir e-mail adresi girin';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Şifre gerekli';
                        if (value.length < 6)
                          return 'Şifre en az 6 karakter olmalı';
                        return null;
                      },
                    ),
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ForgotPasswordPage(),
                            ),
                          );
                        },
                        child: Text('Şifremi Unuttum?'),
                      ),
                    ),
                    SizedBox(height: 20),

                    // ✅ Giriş Butonu (ViewModel destekli)
                    Consumer<UserViewModel>(
                      builder: (context, userViewModel, _) {
                        return SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: userViewModel.isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: userViewModel.isLoading
                                ? const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Giriş Yap',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'veya',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              SizedBox(height: 20),

              // Google ile Giriş
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    final GoogleSignInAccount? googleUser = await _googleSignIn
                        .signIn();
                    if (googleUser == null) return;

                    final String? name = googleUser.displayName;
                    final String email = googleUser.email;

                    print("Giriş başarılı: $name - $email");

                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => HomePage()),
                    );
                  } catch (error) {
                    if (!mounted) return;
                    ErrorHandler.showErrorSnackBar(context, error);
                  }
                },
                icon: Icon(Icons.g_mobiledata, color: Colors.red),
                label: Text('Google ile Giriş Yap'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Hesabınız yok mu? '),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: Text(
                      'Kayıt Ol',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
