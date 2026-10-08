import 'package:flutter/material.dart';

import '../../../models/goal_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/category_style.dart';

/// Hedefin adına göre ikon ve sabit renk tonu.
/// (Modelde ikon/renk alanı yok; böylece her hedef her yerde aynı görünür.)
CategoryStyle goalStyle(Goal goal) {
  final name = goal.name.toLowerCase();
  const keywords = <List<String>, IconData>{
    ['tatil', 'seyahat', 'gezi', 'yurt dışı', 'japonya', 'avrupa']: Icons.flight_outlined,
    ['araba', 'araç', 'otomobil', 'motor']: Icons.directions_car_outlined,
    ['ev', 'konut', 'daire', 'kira', 'peşinat']: Icons.home_outlined,
    ['bilgisayar', 'laptop', 'telefon', 'tablet']: Icons.laptop_mac_outlined,
    ['acil', 'fon', 'birikim', 'yedek']: Icons.shield_outlined,
    ['düğün', 'evlilik', 'nişan']: Icons.favorite_border,
    ['eğitim', 'okul', 'kurs', 'üniversite', 'yüksek lisans']: Icons.school_outlined,
    ['bebek', 'çocuk']: Icons.child_care_outlined,
    ['emeklilik', 'yatırım']: Icons.trending_up,
    ['hediye']: Icons.card_giftcard_outlined,
  };
  IconData icon = Icons.flag_outlined;
  for (final entry in keywords.entries) {
    if (entry.key.any(name.contains)) {
      icon = entry.value;
      break;
    }
  }
  const tones = [Tone.teal, Tone.purple, Tone.orange, Tone.pink, Tone.blue, Tone.green];
  // Renk addan hesaplanır: form önizlemesi ile listedeki kart aynı renkte olur
  final hash = goal.name.trim().toLowerCase().codeUnits
      .fold<int>(0, (h, c) => (h * 31 + c) & 0x7fffffff);
  return CategoryStyle(icon, tones[hash % tones.length]);
}
