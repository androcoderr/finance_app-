import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/profile_view_model.dart';
import '../view_model/user_view_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    // Sayfa ilk açıldığında, UserViewModel'den mevcut kullanıcı bilgilerini alıp
    // controller'ları dolduruyoruz. `read` kullanıyoruz çünkü burada dinleme yapmaya gerek yok.
    final user = context.read<UserViewModel>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 YENİ: UserViewModel'i burada bir kez okuyarak token'a kolayca erişiyoruz.
    final userViewModel = context.read<UserViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Profil Bilgileri'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Consumer<ProfileViewModel>(
        builder: (context, profileViewModel, child) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(24),
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Ad Soyad',
                  icon: Icons.person_outline,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'E-posta Adresi',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 32),
                _buildSaveButton(profileViewModel, userViewModel),
                SizedBox(height: 24),
                Divider(),
                SizedBox(height: 24),
                _buildChangePasswordButton(context, userViewModel),
              ],
            ),
          );
        },
      ),
    );
  }

  TextFormField _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label alanı boş bırakılamaz';
        }
        if (label.contains('E-posta') && !value.contains('@')) {
          return 'Geçerli bir e-posta adresi girin';
        }
        return null;
      },
    );
  }

  Widget _buildSaveButton(
    ProfileViewModel profileViewModel,
    UserViewModel userViewModel,
  ) {
    if (profileViewModel.updateProfileState == ProfileState.loading) {
      return Center(child: CircularProgressIndicator());
    }
    return ElevatedButton.icon(
      icon: Icon(Icons.save_alt_outlined),
      label: Text('Bilgileri Güncelle'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          // 🟢 DÜZELTME: userViewModel'den token'ı alıp ProfileViewModel'e iletiyoruz.
          final token = userViewModel.authToken;
          if (token == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Oturum bulunamadı. Lütfen tekrar giriş yapın.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          final updatedUser = await profileViewModel.updateProfile(
            token,
            _nameController.text,
            _emailController.text,
          );

          if (mounted) {
            final success = updatedUser != null;
            if (success) {
              // 🟢 YENİ: Ana UserViewModel'i de güncelleyerek UI'ın her yerde (örn. Drawer) yenilenmesini sağlıyoruz.
              userViewModel.updateUser(updatedUser);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Profil başarıyla güncellendi!'
                      : (profileViewModel.errorMessage ?? 'Bir hata oluştu'),
                ),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  Widget _buildChangePasswordButton(
    BuildContext context,
    UserViewModel userViewModel,
  ) {
    return OutlinedButton.icon(
      icon: Icon(Icons.lock_outline),
      label: Text('Şifre Değiştir'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: BorderSide(color: Colors.grey.shade300),
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      onPressed: () => _showChangePasswordDialog(context, userViewModel),
    );
  }

  void _showChangePasswordDialog(
    BuildContext context,
    UserViewModel userViewModel,
  ) {
    final passwordFormKey = GlobalKey<FormState>();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Consumer<ProfileViewModel>(
        builder: (context, profileViewModel, child) {
          return AlertDialog(
            title: Text('Şifre Değiştir'),
            content: Form(
              key: passwordFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (profileViewModel.changePasswordState ==
                      ProfileState.loading)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    )
                  else ...[
                    TextFormField(
                      controller: oldPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: 'Mevcut Şifre'),
                      validator: (v) => v!.isEmpty ? 'Boş olamaz' : null,
                    ),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: 'Yeni Şifre'),
                      validator: (v) => (v?.length ?? 0) < 6
                          ? 'En az 6 karakter olmalı'
                          : null,
                    ),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Yeni Şifre (Tekrar)',
                      ),
                      validator: (v) => v != newPasswordController.text
                          ? 'Şifreler uyuşmuyor'
                          : null,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('İptal'),
              ),
              ElevatedButton(
                onPressed:
                    profileViewModel.changePasswordState == ProfileState.loading
                    ? null
                    : () async {
                        if (passwordFormKey.currentState!.validate()) {
                          // 🟢 DÜZELTME: userViewModel'den token'ı alıp ProfileViewModel'e iletiyoruz.
                          final token = userViewModel.authToken;
                          if (token == null) {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Oturum bulunamadı. Lütfen tekrar giriş yapın.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final success = await profileViewModel.changePassword(
                            token,
                            oldPasswordController.text,
                            newPasswordController.text,
                          );
                          if (!mounted) return;
                          Navigator.of(ctx).pop(); // Dialog'u kapat
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Şifre başarıyla değiştirildi!'
                                    : (profileViewModel.errorMessage ?? 'Bir hata oluştu'),
                              ),
                              backgroundColor: success
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          );
                        }
                      },
                child: Text('Değiştir'),
              ),
            ],
          );
        },
      ),
    );
  }
}
