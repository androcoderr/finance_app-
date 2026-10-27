// Uygulama genelinde kullanılan ortak arayüz bileşenleri.
// Ekranlar renk/ölçü sabitleri yerine bunları kullanır.
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/category_style.dart';
import '../../../utils/money.dart';

export '../../../theme/app_colors.dart';
export '../../../theme/app_theme.dart';
export '../../../theme/category_style.dart';
export '../../../utils/money.dart';

/// İnce çerçeveli, gölgesiz kart
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = AppRadius.lg,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor ?? c.border),
    );
    return Material(
      color: color ?? c.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Pastel arka planlı ikon kutusu (kategori, özellik ikonları)
class ToneIcon extends StatelessWidget {
  final IconData icon;
  final Tone tone;
  final double size;

  const ToneIcon({
    super.key,
    required this.icon,
    required this.tone,
    this.size = 44,
  });

  factory ToneIcon.category(String? name, {double size = 44}) {
    final s = CategoryStyle.of(name);
    return ToneIcon(icon: s.icon, tone: s.tone, size: size);
  }

  factory ToneIcon.bill(String? category, {double size = 44}) {
    final s = BillCategoryStyle.of(category);
    return ToneIcon(icon: s.icon, tone: s.tone, size: size);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tone(tone);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: t.background,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: t.foreground, size: size * 0.5),
    );
  }
}

/// Bölüm başlığı + isteğe bağlı "Tümü" bağlantısı
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const SectionHeader(
    this.title, {
    super.key,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpace.page,
      AppSpace.xl,
      AppSpace.page,
      AppSpace.md,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: TextStyle(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Küçük büyük harfli grup başlığı ("GÖRÜNÜM", "BU HAFTA")
class Overline extends StatelessWidget {
  final String text;
  final Color? color;
  const Overline(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) => Text(
        trUpper(text),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      );
}

/// Tek satır: sığmazsa taşmak/alt satıra kaymak yerine küçülür (tutarlar için)
class FitLine extends StatelessWidget {
  final Widget child;
  final AlignmentGeometry alignment;
  const FitLine(this.child, {super.key, this.alignment = AlignmentDirectional.centerStart});

  @override
  Widget build(BuildContext context) =>
      FittedBox(fit: BoxFit.scaleDown, alignment: alignment, child: child);
}

/// Büyük tutar: tam kısım kalın, kuruş küçük ve soluk (₺18.420,50)
class MoneyText extends StatelessWidget {
  final double amount;
  final double fontSize;
  final Color? color;
  final bool hidden;

  const MoneyText(
    this.amount, {
    super.key,
    this.fontSize = 40,
    this.color,
    this.hidden = false,
  });

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -fontSize * 0.035,
      height: 1.05,
      color: color ?? context.colors.text,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    if (hidden) return FitLine(Text(Money.hidden, style: base, maxLines: 1));
    final (whole, cents) = Money.split(amount);
    return FitLine(Text.rich(
      TextSpan(
        children: [
          TextSpan(text: whole),
          TextSpan(
            text: cents,
            style: TextStyle(
              fontSize: fontSize * 0.55,
              color: (color ?? context.colors.text).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
      style: base,
      maxLines: 1,
    ));
  }
}

/// Liste satırlarında gelir/gider tutarı (renkli, işaretli)
class AmountLabel extends StatelessWidget {
  final double amount;
  final bool isIncome;
  final bool hidden;
  final double fontSize;

  const AmountLabel({
    super.key,
    required this.amount,
    required this.isIncome,
    this.hidden = false,
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Text(
      hidden ? Money.hidden : Money.format(isIncome ? amount : -amount, sign: true),
      maxLines: 1,
      softWrap: false,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: isIncome ? c.income : c.text,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Durum rozeti ("2 gün kaldı", "Ödendi")
class StatusPill extends StatelessWidget {
  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  const StatusPill({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Boş liste durumu
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, size: 34, color: c.textFaint),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textMuted),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpace.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Ana buton: tam genişlik, sağda ikon, yükleniyor durumu
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool destructive;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward,
    this.loading = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: destructive
          ? ElevatedButton.styleFrom(
              backgroundColor: c.expense,
              foregroundColor: Colors.white,
            )
          : null,
      child: loading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: c.primary,
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Expanded(child: Text(label)),
                  if (icon != null) Icon(icon, size: 20),
                ],
              ),
            ),
    );
  }
}

/// Üstte etiket, altta alan (tasarımdaki form düzeni)
class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const LabeledField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Görünen etiket ekran okuyucuda ayrıca okunmaz; alanın kendisine verilir.
        // (MergeSemantics kullanılmaz: alanı yanındaki "şifreyi göster" gibi
        // düğmelerle tek öğeye çevirip metin kutusunu düğme yapıyordu.)
        ExcludeSemantics(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.colors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Semantics(label: label, child: child),
      ],
    );
  }
}

/// Türkçe büyük harf: Dart'ın toUpperCase'i "i"yi "I" yapar ("BİRİKİM" yerine "BIRIKIM")
String trUpper(String s) => s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

/// Ad soyaddan baş harfler ("Ayşe Kaya" -> "AK")
String initialsOf(String? name) {
  final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final letters = parts.take(2).map((p) => trUpper(p.characters.first));
  final s = letters.join();
  return s.isEmpty ? '?' : s;
}

/// Baş harfli kare avatar
class InitialsAvatar extends StatelessWidget {
  final String? name;
  final double size;
  final Color? background;
  final Color? foreground;

  const InitialsAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? c.primarySoft,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Text(
        initialsOf(name),
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
          color: foreground ?? c.primary,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
