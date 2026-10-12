// Uçtan uca duman testi: uygulama açılır, giriş yapılır, ana sayfa ve
// Tüm işlemler açılır. Yerel sunucu çalışırken (docker compose up) gerçek
// cihaz/simülatörde: flutter test integration_test -d <cihaz>
//
// Hesap: --dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=...
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:test_borsa/main.dart' as app;

const _email = String.fromEnvironment('TEST_EMAIL', defaultValue: 'deneme@example.com');
const _password = String.fromEnvironment('TEST_PASSWORD', defaultValue: 'Deneme123!');

Future<void> waitFor(WidgetTester tester, Finder finder, {int seconds = 20}) async {
  for (var i = 0; i < seconds * 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Bulunamadı: $finder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('giriş → ana sayfa → tüm işlemler', (tester) async {
    app.main();

    // Oturum açıksa doğrudan ana sayfa gelir; değilse giriş yapılır
    final login = find.text('Giriş yap');
    final home = find.text('Merhaba');
    for (var i = 0; i < 80 && login.evaluate().isEmpty && home.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    if (home.evaluate().isEmpty) {
      await tester.enterText(find.byType(TextFormField).at(0), _email);
      await tester.enterText(find.byType(TextFormField).at(1), _password);
      await tester.tap(login);
      await waitFor(tester, home);
    }
    expect(find.text('TOPLAM BAKİYE'), findsOneWidget);

    // Son işlemler › Tümü
    // Liste tembel kurulur: önce bölüme kaydır, sonra o bölümdeki "Tümü"
    await tester.scrollUntilVisible(find.text('Son işlemler'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tümü').last);
    await waitFor(tester, find.text('Tüm işlemler'));
    expect(find.textContaining('işlem'), findsWidgets);
  });
}
