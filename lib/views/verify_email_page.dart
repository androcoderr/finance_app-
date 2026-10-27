import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/user_service.dart';
import '../view_model/user_view_model.dart';
import 'widgets/ui/ui.dart';

/// Kayıttan (veya doğrulanmamış hesapla girişten) sonra e-postaya giden
/// 6 haneli kodun girildiği ekran. Doğrulanınca oturum açılır.
class VerifyEmailPage extends StatefulWidget {
  final String email;
  final String password; // Kayıt/giriş ekranında az önce yazılan şifre
  const VerifyEmailPage({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  static const _codeLength = 6;
  static const _cooldown = 60;

  final _codeController = TextEditingController();
  final _focus = FocusNode();
  bool _verifying = false;
  String? _error;
  int _secondsLeft = _cooldown; // Kod az önce gönderildi
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown(_cooldown);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _timer?.cancel();
    setState(() => _secondsLeft = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  Future<void> _verify() async {
    final code = _codeController.text;
    if (code.length != _codeLength || _verifying) return;
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final result =
          await AuthService.verifyEmail(widget.email, code, widget.password);
      if (!mounted) return;
      await context.read<UserViewModel>().completeEmailVerification(result);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-postan doğrulandı, hoş geldin!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = e.toString().replaceFirst('Exception: ', '');
        _codeController.clear();
      });
      _focus.requestFocus();
    }
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AuthService.resendVerificationCode(widget.email);
      if (!mounted) return;
      setState(() => _error = null);
      _startCooldown(_cooldown);
      messenger.showSnackBar(const SnackBar(content: Text('Yeni kod gönderildi')));
    } on ResendCooldownException catch (e) {
      if (!mounted) return;
      _startCooldown(e.retryAfter);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String get _countdown {
    final m = _secondsLeft ~/ 60;
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.page,
            AppSpace.sm,
            AppSpace.page,
            AppSpace.xl,
          ),
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: ToneIcon(
                icon: Icons.mark_email_unread_outlined,
                tone: Tone.blue,
                size: 64,
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            Text(
              'E-postanı\ndoğrula',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontSize: 34),
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                style: TextStyle(color: c.textMuted, fontSize: 15, height: 1.45),
                children: [
                  TextSpan(
                    text: widget.email,
                    style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(
                    text: ' adresine 6 haneli bir kod gönderdik. '
                        'Gelen kutunu ve spam klasörünü kontrol et.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _CodeBoxes(
              controller: _codeController,
              focusNode: _focus,
              length: _codeLength,
              hasError: _error != null,
              onChanged: (v) {
                if (_error != null) setState(() => _error = null);
                setState(() {});
                if (v.length == _codeLength) _verify();
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpace.md),
              Row(
                children: [
                  Icon(Icons.error_outline, size: 18, color: c.expense),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: c.expense, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 28),
            AppButton(
              label: 'Doğrula',
              icon: Icons.check,
              loading: _verifying,
              onPressed: _codeController.text.length == _codeLength ? _verify : null,
            ),
            const SizedBox(height: AppSpace.lg),
            Center(
              child: _secondsLeft > 0
                  ? Text(
                      'Yeni kodu $_countdown sonra isteyebilirsin',
                      style: TextStyle(color: c.textFaint),
                    )
                  : TextButton.icon(
                      onPressed: _resend,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Kodu tekrar gönder'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tek gizli metin alanı + 6 görsel kutu (yapıştırma ve otomatik doldurma çalışır)
class _CodeBoxes extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const _CodeBoxes({
    required this.controller,
    required this.focusNode,
    required this.length,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = controller.text;
    return GestureDetector(
      onTap: () => focusNode.requestFocus(),
      child: Stack(
        children: [
          // Görünmez ama odaklanabilir gerçek alan
          Opacity(
            opacity: 0,
            child: SizedBox(
              height: 64,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofillHints: const [AutofillHints.oneTimeCode],
                keyboardType: TextInputType.number,
                maxLength: length,
                showCursor: false,
                enableInteractiveSelection: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(counterText: ''),
                onChanged: onChanged,
              ),
            ),
          ),
          IgnorePointer(
            child: ListenableBuilder(
              listenable: focusNode,
              builder: (context, _) => Row(
                children: [
                  for (var i = 0; i < length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            width: 1.6,
                            color: hasError
                                ? c.expense
                                : (focusNode.hasFocus && i == text.length)
                                    ? c.primary
                                    : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          i < text.length ? text[i] : '',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: c.text,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
