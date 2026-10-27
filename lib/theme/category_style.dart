import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Kategori adına göre ikon ve renk tonu. Tüm ekranlar bunu kullanır,
/// böylece "Market" her yerde aynı ikon ve renkte görünür.
class CategoryStyle {
  final IconData icon;
  final Tone tone;
  const CategoryStyle(this.icon, this.tone);

  static const _styles = <String, CategoryStyle>{
    // Giderler
    'Market': CategoryStyle(Icons.shopping_cart_outlined, Tone.orange),
    'Alışveriş': CategoryStyle(Icons.shopping_bag_outlined, Tone.purple),
    'Yiyecek': CategoryStyle(Icons.restaurant_outlined, Tone.red),
    'Telefon': CategoryStyle(Icons.smartphone_outlined, Tone.blue),
    'Eğlence': CategoryStyle(Icons.movie_outlined, Tone.pink),
    'Eğitim': CategoryStyle(Icons.school_outlined, Tone.blue),
    'Güzellik': CategoryStyle(Icons.spa_outlined, Tone.pink),
    'Spor': CategoryStyle(Icons.fitness_center_outlined, Tone.teal),
    'Sosyal': CategoryStyle(Icons.groups_outlined, Tone.purple),
    'Ulaşım': CategoryStyle(Icons.directions_bus_outlined, Tone.blue),
    'Giyim': CategoryStyle(Icons.checkroom_outlined, Tone.purple),
    'Araba': CategoryStyle(Icons.directions_car_outlined, Tone.grey),
    'İçecekler': CategoryStyle(Icons.local_cafe_outlined, Tone.yellow),
    'Sigara': CategoryStyle(Icons.smoking_rooms_outlined, Tone.grey),
    'Elektronik': CategoryStyle(Icons.devices_outlined, Tone.blue),
    'Seyahat': CategoryStyle(Icons.flight_outlined, Tone.teal),
    'Sağlık': CategoryStyle(Icons.favorite_border, Tone.red),
    'Pet': CategoryStyle(Icons.pets_outlined, Tone.yellow),
    'Onarım': CategoryStyle(Icons.build_outlined, Tone.grey),
    'Konut': CategoryStyle(Icons.home_outlined, Tone.purple),
    'Mobilya': CategoryStyle(Icons.chair_outlined, Tone.orange),
    'Hediyeler': CategoryStyle(Icons.card_giftcard_outlined, Tone.pink),
    'Bağış': CategoryStyle(Icons.volunteer_activism_outlined, Tone.green),
    'Oyun': CategoryStyle(Icons.sports_esports_outlined, Tone.purple),
    'Atıştırmalık': CategoryStyle(Icons.cookie_outlined, Tone.yellow),
    'Çocuk': CategoryStyle(Icons.child_care_outlined, Tone.pink),
    'Faturalar': CategoryStyle(Icons.receipt_long_outlined, Tone.yellow),
    'Diğer': CategoryStyle(Icons.category_outlined, Tone.grey),
    // Gelirler
    'Maaş': CategoryStyle(Icons.work_outline, Tone.green),
    'Prim': CategoryStyle(Icons.emoji_events_outlined, Tone.green),
    'Hediye': CategoryStyle(Icons.redeem_outlined, Tone.pink),
    'Yatırım': CategoryStyle(Icons.trending_up, Tone.teal),
    'Ek Gelir': CategoryStyle(Icons.add_card_outlined, Tone.green),
    'Faiz': CategoryStyle(Icons.account_balance_outlined, Tone.teal),
    'Diğer Gelir': CategoryStyle(Icons.payments_outlined, Tone.grey),
  };

  static const fallback = CategoryStyle(Icons.category_outlined, Tone.grey);

  static CategoryStyle of(String? name) => _styles[name] ?? fallback;
}

/// Fatura kategorileri (faturalar ekranındaki seçenekler)
class BillCategoryStyle {
  static const _styles = <String, CategoryStyle>{
    'Elektrik': CategoryStyle(Icons.bolt_outlined, Tone.yellow),
    'Su': CategoryStyle(Icons.water_drop_outlined, Tone.blue),
    'Doğalgaz': CategoryStyle(Icons.local_fire_department_outlined, Tone.red),
    'İnternet': CategoryStyle(Icons.wifi, Tone.teal),
    'Telefon': CategoryStyle(Icons.smartphone_outlined, Tone.purple),
    'Kira': CategoryStyle(Icons.home_outlined, Tone.purple),
    'Kredi Kartı': CategoryStyle(Icons.credit_card_outlined, Tone.orange),
    'Sigorta': CategoryStyle(Icons.shield_outlined, Tone.green),
    'Diğer': CategoryStyle(Icons.receipt_outlined, Tone.grey),
  };

  static CategoryStyle of(String? name) =>
      _styles[name] ?? CategoryStyle.fallback;
}
