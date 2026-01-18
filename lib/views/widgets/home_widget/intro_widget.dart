// IntroSliderSection'ı içeren basit bir Scaffold yapısı
import 'dart:async';

import 'package:flutter/material.dart';

class IntroSliderScreenContainer extends StatelessWidget {
  const IntroSliderScreenContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uygulama Tanıtım Şeridi'),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(child: IntroSliderSection()),
    );
  }
}

// Tanıtım Verileri
final List<Map<String, dynamic>> introData = [
  {
    'text': "Harcamaların Kontrol Altında, Bütçen Güvende! 💸",
    'icon': Icons.account_balance_wallet,
    'color': Colors.deepPurple[100],
  },
  {
    'text': "Fişler Dijitalleşsin, Harcamaların Kaybolmasın. 🧾✨",
    'icon': Icons.receipt_long,
    'color': Colors.green[100],
  },
  {
    'text':
        "Beklenmedik Harcamalara Son! Anormal Davranışları Anında Yakala. 🚨",
    'icon': Icons.warning_amber,
    'color': Colors.red[100],
  },
  {
    'text': "Finansal Hedeflerine Ulaş! Riskleri Belirle, Akıllıca Yönet. 🎯",
    'icon': Icons.analytics_outlined,
    'color': Colors.orange[100],
  },
  {
    'text': "Görsel Raporlarla Bütçene Hakim Ol. Tek Tıkla PDF İndir! 📊",
    'icon': Icons.picture_as_pdf,
    'color': Colors.teal[100],
  },
  {
    'text': "Geleceğe Güvenle Bak! Kişisel Finans Asistanın Hep Yanında. ⭐",
    'icon': Icons.assistant_photo,
    'color': Colors.cyan[100],
  },
];

// EKSİK OLAN ÜST SINIF TANIMI BURADA:
class IntroSliderSection extends StatefulWidget {
  const IntroSliderSection({super.key});

  @override
  State<IntroSliderSection> createState() => _IntroSliderSectionState();
}

class _IntroSliderSectionState extends State<IntroSliderSection> {
  // Sonsuz kaydırma için başlangıç indeksi: 1000 döngü kadar öteden başlıyoruz
  final PageController _pageController = PageController(
    initialPage: 1000 * introData.length,
  );
  int _currentPage = 1000 * introData.length;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    // Otomatik kaydırma için Timer başlat (4 saniyede bir)
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (!_pageController.hasClients) return;

      _currentPage++;

      // Yumuşak geçiş
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeIn,
      );

      // Sıçrama Mantığı: Sayaç çok ilerlediğinde, kullanıcı fark etmeden controller pozisyonunu sıfırlarız.
      // Bu, sayfa sayısının sonsuza kadar büyümesini engellerken, kesintisiz bir döngü hissi verir.
      if (_currentPage > 1000 * introData.length + introData.length) {
        // İlk döngüye sıçrama
        _pageController.jumpToPage(1000 * introData.length);
        _currentPage = 1000 * introData.length;
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ekran yüksekliğinin %18'ini hesaplama
    final double screenHeight = MediaQuery.of(context).size.height;
    final double desiredHeight = screenHeight * 0.12;

    return SizedBox(
      height: desiredHeight,
      // Genişliğin tamamını kullanmak için dış padding'i kaldırıyoruz
      width: double.infinity,
      child: PageView.builder(
        controller: _pageController,
        // item sayısı sonsuz kabul edilir
        itemCount: null,

        onPageChanged: (int page) {
          _currentPage = page;
        },

        itemBuilder: (context, index) {
          // Gerçek indeksi modulo (kalan) ile buluruz: 0, 1, 2, 3, 4, 5, 0, 1, ...
          final int realIndex = index % introData.length;

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
            ), // Yanlarda hafif boşluk
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              color: introData[realIndex]['color'],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      introData[realIndex]['icon'],
                      size: 30,
                      color: Colors.deepPurple[800],
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        introData[realIndex]['text'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
