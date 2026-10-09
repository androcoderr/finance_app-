import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/profile_view_model.dart';
import '../view_model/user_view_model.dart';
import '../view_model/setting_helper_methods.dart';
import 'widgets/ui/ui.dart';

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

  Future<void> _save(ProfileViewModel profileViewModel, UserViewModel userViewModel) async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final token = userViewModel.authToken;
    if (token == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Oturum bulunamadı, tekrar giriş yap')),
      );
      return;
    }
    final updatedUser = await profileViewModel.updateProfile(
      token,
      _nameController.text.trim(),
      _emailController.text.trim(),
    );
    if (!mounted) return;
    if (updatedUser != null) userViewModel.updateUser(updatedUser);
    messenger.showSnackBar(SnackBar(
      content: Text(updatedUser != null
          ? 'Profil güncellendi'
          : (profileViewModel.errorMessage ?? 'Bir hata oluştu')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final userViewModel = context.read<UserViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Consumer<ProfileViewModel>(
        builder: (context, profileViewModel, child) {
          final saving = profileViewModel.updateProfileState == ProfileState.loading;
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.xl),
              children: [
                Center(
                  child: ValueListenableBuilder(
                    valueListenable: _nameController,
                    builder: (_, value, __) => InitialsAvatar(
                      name: value.text,
                      size: 84,
                      background: AppColors.brandBlue,
                      foreground: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                LabeledField(
                  label: 'Ad soyad',
                  child: TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                    validator: (v) => (v == null || v.trim().length < 2)
                        ? 'Ad soyad en az 2 karakter olmalı'
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                // E-posta giriş kimliği ve şifre sıfırlama adresi: sunucu yeni
                // adresi doğrulayana kadar uygulamadan değiştirilemez
                LabeledField(
                  label: 'E-posta',
                  child: TextFormField(
                    controller: _emailController,
                    readOnly: true,
                    style: TextStyle(color: c.textMuted),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.mail_outline, size: 20),
                      suffixIcon: Icon(Icons.verified_outlined, color: c.income, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'E-posta adresini değiştirmek için Ayarlar › Bize yaz.',
                  style: TextStyle(color: c.textFaint, fontSize: 12.5),
                ),
                const SizedBox(height: AppSpace.xl),
                AppButton(
                  label: 'Kaydet',
                  icon: Icons.check,
                  loading: saving,
                  onPressed: () => _save(profileViewModel, userViewModel),
                ),
                const SizedBox(height: AppSpace.md),
                OutlinedButton.icon(
                  onPressed: () => _showChangePasswordDialog(context, userViewModel),
                  icon: const Icon(Icons.lock_outline, size: 20),
                  label: const Text('Şifre değiştir'),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  decoration: BoxDecoration(
                    color: c.expenseSoft,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: c.expense, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Hesabı sil',
                            style: TextStyle(
                              color: c.expense,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tüm işlem, hedef ve faturaların kalıcı olarak silinir. Geri alınamaz.',
                        style: TextStyle(color: c.text, height: 1.4),
                      ),
                      const SizedBox(height: AppSpace.md),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: c.expense,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 42),
                        ),
                        onPressed: () => showDeleteAccountDialog(context),
                        child: const Text('Hesabımı sil'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
                      validator: (v) => (v?.length ?? 0) < 8
                          ? 'En az 8 karakter olmalı'
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
                          // Hata olursa (ör. eski şifre yanlış) dialog açık kalsın,
                          // kullanıcı tüm alanları baştan doldurmasın
                          if (!ctx.mounted) return;
                          if (success) Navigator.of(ctx).pop();
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
