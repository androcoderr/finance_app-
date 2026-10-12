import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:test_borsa/view_model/user_view_model.dart';
import 'package:test_borsa/views/login_screen.dart';
import 'package:test_borsa/views/widgets/ui/ui.dart';

Widget app(Widget child) => MaterialApp(theme: AppTheme.light(), home: child);

void main() {
  testWidgets('Büyük tutar dar alanda taşmadan tek satıra sığar', (tester) async {
    await tester.pumpWidget(app(const Scaffold(
      body: Center(
        child: SizedBox(width: 120, child: MoneyText(123456789.99, fontSize: 40)),
      ),
    )));
    // Taşma olsaydı Flutter bir "overflowed" hatası fırlatırdı
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(MoneyText)).width, lessThanOrEqualTo(120));
  });

  testWidgets('Büyük yazı boyutunda (1.3x) da taşma yok', (tester) async {
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
      child: app(const Scaffold(
        body: Center(
          child: SizedBox(
            width: 90,
            child: FitLine(Text('₺15.256,49', maxLines: 1, style: TextStyle(fontSize: 20))),
          ),
        ),
      )),
    ));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Giriş formu boş gönderilince uyarı gösterir, sunucuya gitmez', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    final vm = UserViewModel();
    await tester.pumpWidget(ChangeNotifierProvider<UserViewModel>.value(
      value: vm,
      child: app(LoginScreen()),
    ));
    await tester.tap(find.text('Giriş yap'));
    await tester.pump();

    expect(find.text('E-posta adresi gerekli'), findsOneWidget);
    expect(vm.isLoggedIn, isFalse);

    await tester.enterText(find.byType(TextFormField).first, 'gecersiz-eposta');
    await tester.tap(find.text('Giriş yap'));
    await tester.pump();
    expect(find.text('Geçerli bir e-posta adresi girin'), findsOneWidget);
  });
}
