// Hakkımızda Sayfası

import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hakkımızda')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 32),
            Icon(
              Icons.account_balance,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 16),
            Text(
              'Test Borsa',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Sürüm 1.0.0', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 32),
            Text(
              'MİSYONUMUZ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Finansal yönetiminizi kolaylaştırmak ve '
              'bilinçli harcama alışkanlıkları kazandırmak için '
              'geliştirilmiş modern bir çözüm sunuyoruz.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              'VİZYONUMUZ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Herkesin finansal özgürlüğe ulaşabileceği '
              'bir dünya hayal ediyoruz. Test Borsa ile '
              'bütçenizi kontrol altında tutun, hedeflerinize ulaşın.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 32),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.favorite, color: Colors.red, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'Bizi seçtiğiniz için teşekkür ederiz!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
