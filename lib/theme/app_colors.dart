import 'package:flutter/material.dart';

/// Uygulamanın renk paleti. Ekranlarda doğrudan `Colors.x` yerine
/// `context.colors.x` kullanılır; böylece açık/koyu tema tek yerden yönetilir.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color primary;
  final Color onPrimary;
  final Color primarySoft; // Seçili arka planlar, rozetler
  final Color background;
  final Color surface; // Kartlar
  final Color surfaceMuted; // Form alanları, pasif butonlar
  final Color border;
  final Color text;
  final Color textMuted;
  final Color textFaint;
  final Color income;
  final Color incomeSoft;
  final Color expense;
  final Color expenseSoft;
  final Color warning;
  final Color warningSoft;
  final Color ink; // Koyu vurgu kartları
  final Color onInk;

  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.income,
    required this.incomeSoft,
    required this.expense,
    required this.expenseSoft,
    required this.warning,
    required this.warningSoft,
    required this.ink,
    required this.onInk,
  });

  static const light = AppColors(
    primary: Color(0xFF0B5CD5),
    onPrimary: Colors.white,
    primarySoft: Color(0xFFE6EEFC),
    background: Color(0xFFF5F6F8),
    surface: Colors.white,
    surfaceMuted: Color(0xFFEEF0F3),
    border: Color(0xFFE4E7EC),
    text: Color(0xFF12151B),
    textMuted: Color(0xFF5C6370),
    textFaint: Color(0xFF8C929D),
    income: Color(0xFF12805C),
    incomeSoft: Color(0xFFE2F4EB),
    expense: Color(0xFFD23B3B),
    expenseSoft: Color(0xFFFCE8E8),
    warning: Color(0xFFB45F06),
    warningSoft: Color(0xFFFFF0D9),
    ink: Color(0xFF12151B),
    onInk: Colors.white,
  );

  static const dark = AppColors(
    primary: Color(0xFF5A9BFF),
    onPrimary: Color(0xFF06152E),
    primarySoft: Color(0xFF1A2A45),
    background: Color(0xFF0D1015),
    surface: Color(0xFF161A21),
    surfaceMuted: Color(0xFF1F242D),
    border: Color(0xFF2A303A),
    text: Color(0xFFEDEFF3),
    textMuted: Color(0xFFA4AAB6),
    textFaint: Color(0xFF6F7682),
    income: Color(0xFF3FD38E),
    incomeSoft: Color(0xFF14301F),
    expense: Color(0xFFFF6B6B),
    expenseSoft: Color(0xFF3A1A1C),
    warning: Color(0xFFFFB454),
    warningSoft: Color(0xFF3A2A12),
    ink: Color(0xFF232935),
    onInk: Color(0xFFEDEFF3),
  );

  /// Ana sayfa üst alanı gibi mavi bölümler (iki temada da aynı mavi tonu)
  static const brandBlue = Color(0xFF0B5CD5);
  static const brandBlueDark = Color(0xFF0848AA);

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      primarySoft: l(primarySoft, other.primarySoft),
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      border: l(border, other.border),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      textFaint: l(textFaint, other.textFaint),
      income: l(income, other.income),
      incomeSoft: l(incomeSoft, other.incomeSoft),
      expense: l(expense, other.expense),
      expenseSoft: l(expenseSoft, other.expenseSoft),
      warning: l(warning, other.warning),
      warningSoft: l(warningSoft, other.warningSoft),
      ink: l(ink, other.ink),
      onInk: l(onInk, other.onInk),
    );
  }
}

/// Kategori ve özellik ikonlarının pastel kutu renkleri
enum Tone { blue, purple, teal, orange, pink, yellow, green, red, grey }

class ToneColors {
  final Color background;
  final Color foreground;
  const ToneColors(this.background, this.foreground);
}

extension ToneX on Tone {
  ToneColors resolve(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    const light = {
      Tone.blue: ToneColors(Color(0xFFE3EDFD), Color(0xFF1F5FD1)),
      Tone.purple: ToneColors(Color(0xFFEEE8FB), Color(0xFF6A43C9)),
      Tone.teal: ToneColors(Color(0xFFDDF3F3), Color(0xFF0F7F7F)),
      Tone.orange: ToneColors(Color(0xFFFFE9DC), Color(0xFFCB5A17)),
      Tone.pink: ToneColors(Color(0xFFFDE6EF), Color(0xFFC0306A)),
      Tone.yellow: ToneColors(Color(0xFFFFF2D2), Color(0xFFA86A00)),
      Tone.green: ToneColors(Color(0xFFE0F3E7), Color(0xFF1C8150)),
      Tone.red: ToneColors(Color(0xFFFCE5E5), Color(0xFFC73434)),
      Tone.grey: ToneColors(Color(0xFFECEEF1), Color(0xFF59606C)),
    };
    final c = light[this]!;
    if (!dark) return c;
    // Koyu temada: ön plan rengi parlatılır, arka plan onun düşük opaklıkta hali
    final fg = Color.lerp(c.foreground, Colors.white, 0.35)!;
    return ToneColors(fg.withValues(alpha: 0.16), fg);
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  ToneColors tone(Tone t) => t.resolve(Theme.of(this).brightness);
}
