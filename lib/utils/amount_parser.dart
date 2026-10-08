/// Kullanıcının yazdığı tutarı sayıya çevirir. Türkçe yazımı destekler:
///   "250,50" -> 250.5     "1.250,50" -> 1250.5    "1.250" -> 1250
///   "250.50" -> 250.5     "1,250.50" -> 1250.5    "₺ 1 250" -> 1250
/// Geçersizse null döner.
double? parseAmount(String? input) {
  if (input == null) return null;
  var s = input.replaceAll(RegExp(r'[\s₺]'), '');
  if (s.isEmpty) return null;

  final lastComma = s.lastIndexOf(',');
  final lastDot = s.lastIndexOf('.');

  if (lastComma >= 0 && lastDot >= 0) {
    // İkisi de varsa en sondaki ondalık ayırıcıdır, diğeri binlik
    if (lastComma > lastDot) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else {
      s = s.replaceAll(',', '');
    }
  } else if (lastComma >= 0) {
    // Sadece virgül: tek virgül ondalık, birden fazlaysa binlik
    s = ','.allMatches(s).length == 1 ? s.replaceAll(',', '.') : s.replaceAll(',', '');
  } else if (lastDot >= 0) {
    // Sadece nokta: birden fazlaysa ya da noktadan sonra tam 3 hane varsa
    // Türkçe binlik ayırıcı kabul et ("1.250" = bin iki yüz elli)
    final dots = '.'.allMatches(s).length;
    if (dots > 1 || s.length - lastDot - 1 == 3) s = s.replaceAll('.', '');
  }

  return double.tryParse(s);
}
