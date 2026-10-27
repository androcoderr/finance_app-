import 'package:intl/intl.dart';

/// Türkçe para biçimi: ₺18.420,50
class Money {
  static final _withDecimals = NumberFormat('#,##0.00', 'tr_TR');
  static final _noDecimals = NumberFormat('#,##0', 'tr_TR');

  /// [sign]: gelir/gider listelerinde "+₺1.250" / "−₺1.250"
  /// [decimals]: null ise kuruş varsa gösterilir, yoksa gizlenir
  static String format(double amount, {bool sign = false, bool? decimals}) {
    final value = amount.abs();
    final showDecimals = decimals ?? (value != value.roundToDouble());
    final body = (showDecimals ? _withDecimals : _noDecimals).format(value);
    final prefix = sign
        ? (amount < 0 ? '−' : '+')
        : (amount < 0 ? '−' : '');
    return '$prefix₺$body';
  }

  /// Büyük tutar gösterimi için tam kısım ve kuruş ayrı: ("₺18.420", ",50")
  static (String, String) split(double amount) {
    final full = format(amount, decimals: true);
    final i = full.lastIndexOf(',');
    return (full.substring(0, i), full.substring(i));
  }

  /// Yüzde: %12 / %4,5
  static String percent(double value, {int decimals = 0}) {
    final s = value.abs().toStringAsFixed(decimals).replaceAll('.', ',');
    return '%$s';
  }

  static const hidden = '₺ ••••';
}
