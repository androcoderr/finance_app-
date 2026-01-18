import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test_borsa/services/finance_service.dart';
import 'package:test_borsa/services/firebase_service.dart';
import 'package:test_borsa/view_model/analysis_view_model.dart';
import 'package:test_borsa/view_model/bill_view_model.dart';
import 'package:test_borsa/view_model/export_view_model.dart';
import 'package:test_borsa/view_model/notification_provider.dart';
import 'package:test_borsa/view_model/profile_view_model.dart';
import 'package:test_borsa/view_model/recurring_transaction_view_model.dart';
import 'package:test_borsa/view_model/add_transaction_view_model.dart';
import 'package:test_borsa/view_model/finance_view_model.dart';
import 'package:test_borsa/view_model/home_view_model.dart';
import 'package:test_borsa/view_model/settings_view_model.dart';
import 'package:test_borsa/view_model/user_view_model.dart';
import 'package:test_borsa/views/bill_screen.dart';
import 'package:test_borsa/views/home_page.dart';
import 'package:test_borsa/views/login_screen.dart';
import 'package:test_borsa/views/notification_page.dart';
import 'package:test_borsa/views/register_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:test_borsa/views/reset_password_page.dart';
import 'package:test_borsa/views/widgets/theme_provider.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("--- Arka Planda Mesaj Geldi (Handler) ---");
  FirebaseService.backgroundMessageHandler(message);
}

// Uygulama açıkken gelen 2FA isteği için dialog gösteren fonksiyon.
void _show2faConfirmationDialog({
  required String title,
  required String body,
  required String sessionToken,
}) {
  print('🟢🟢🟢 ADIM 3: Dialog gösterme fonksiyonu ÇAĞRILDI. 🟢🟢🟢');
  final context = navigatorKey.currentContext;
  if (context == null) {
    print("❌ Dialog gösterilemedi: Navigator context bulunamadı.");
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () {
            // Sunucuya "Reddedildi" bilgisini gönder
            FirebaseService.instance.sendVerificationResponse(
              sessionToken,
              false,
            );
            Navigator.of(ctx).pop();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text('Reddet'),
        ),
        ElevatedButton(
          child: Text('Onayla'),
          onPressed: () {
            // Sunucuya "Onaylandı" bilgisini gönder
            FirebaseService.instance.sendVerificationResponse(
              sessionToken,
              true,
            );
            Navigator.of(ctx).pop();
          },
        ),
      ],
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase Core başlatıldı.');

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final firebaseService = FirebaseService.instance;

    await firebaseService.requestNotificationPermissions();
    await firebaseService.getFCMToken();
    await firebaseService.setupInteractedMessage();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('--- Foreground mesaj ---');
      print('data: ${message.data}');

      FirebaseService.foregroundMessageHandler(message);
      if (message.data['navigate'] == 'notifications') {
        Future.microtask(() {
          navigatorKey.currentState?.pushNamed("/notifications");
        });
      }

      if (message.data['type'] == '2fa_request' &&
          message.notification != null) {
        final sessionToken = message.data['session_token'];
        if (sessionToken != null) {
          _show2faConfirmationDialog(
            title: message.notification!.title ?? 'Giriş Onayı',
            body:
                message.notification!.body ??
                'Giriş denemesini onaylıyor musunuz?',
            sessionToken: sessionToken,
          );
        }
      }
    });

    print('✅ Messaging listeners hazır.');
  } catch (e) {
    print('❌ Firebase init hata: $e');
  }

  await initializeDateFormatting('tr_TR', null);

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(MyApp());
}

Future<void> setupFirebaseMessaging() async {
  try {
    FirebaseMessaging.onBackgroundMessage(
      FirebaseService.backgroundMessageHandler,
    );
    FirebaseMessaging.onMessage.listen(
      FirebaseService.foregroundMessageHandler,
    );
    await FirebaseService().requestNotificationPermissions();
    await FirebaseService().getFCMToken();
    print('✅ Firebase Messaging başlatıldı');
  } catch (e) {
    print('❌ Firebase Messaging başlatılamadı: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<void>? _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
    await initializeDateFormatting('tr_TR', null);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<UserViewModel>(create: (_) => UserViewModel()),
        Provider<FinanceService>(create: (_) => FinanceService()),
        ChangeNotifierProvider<FinanceViewModel>(
          create: (context) => FinanceViewModel(
            Provider.of<FinanceService>(context, listen: false),
          ),
        ),
        ChangeNotifierProxyProvider<UserViewModel, HomeViewModel>(
          create: (context) =>
              HomeViewModel(Provider.of<UserViewModel>(context, listen: false)),
          update: (context, userViewModel, previousHomeViewModel) =>
              previousHomeViewModel!,
        ),
        ChangeNotifierProxyProvider<UserViewModel, AddTransactionViewModel>(
          create: (context) => AddTransactionViewModel(
            Provider.of<UserViewModel>(context, listen: false),
          ),
          update: (context, userViewModel, previousAddTxViewModel) =>
              previousAddTxViewModel!,
        ),
        ChangeNotifierProvider<RecurringTransactionViewModel>(
          create: (_) => RecurringTransactionViewModel(),
        ),
        ChangeNotifierProxyProvider<UserViewModel, AnalysisViewModel>(
          create: (context) => AnalysisViewModel(
            Provider.of<UserViewModel>(context, listen: false),
          ),
          update: (context, userViewModel, previousAnalysisViewModel) =>
              previousAnalysisViewModel!,
        ),
        ChangeNotifierProvider<BillsViewModel>(create: (_) => BillsViewModel()),
        ChangeNotifierProvider<ProfileViewModel>(
          create: (_) => ProfileViewModel(),
        ),
        ChangeNotifierProvider<SettingsViewModel>(
          create: (_) => SettingsViewModel(),
        ),
        ChangeNotifierProvider(create: (_) => ExportViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Builder(
        builder: (context) {
          final themeProvider = Provider.of<ThemeProvider>(context);

          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Finans Cepte',
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            home: _AppInitializer(),
            routes: {
              '/login': (context) => LoginScreen(),
              '/register': (context) => RegisterScreen(),
              '/home': (context) => HomePage(),
              '/bills': (context) => BillsPage(),
              '/notifications': (context) => NotificationPage(),
              '/reset-password': (context) {
                final token =
                    ModalRoute.of(context)!.settings.arguments as String;
                return ResetPasswordPage(token: token);
              },
            },
          );
        },
      ),
    );
  }

  // 🎨 AÇIK TEMA
  ThemeData _buildLightTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: Colors.blue.shade700,
      colorScheme: ColorScheme.light(
        primary: Colors.blue.shade700,
        secondary: Colors.blue.shade500,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black,
        error: Colors.red.shade600,
      ),
      scaffoldBackgroundColor: Colors.grey.shade50,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      brightness: Brightness.light,
      useMaterial3: true,
    );
  }

  // 🎨 KARANLIK TEMA - Modern & Göz Alıcı Renkler
  ThemeData _buildDarkTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: Color(0xFF2D5FFF), // Güçlü Mavi
      colorScheme: ColorScheme.dark(
        primary: Color(0xFF2D5FFF), // Canlı Mavi
        secondary: Color(0xFF00D4FF), // Çok Koyu Lacivert
        surface: Color(0xFF151B3F), // Koyu Lacivert (Card)
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFFF0F0F5),
        error: Color(0xFFFF4757), // Kırmızı
        surfaceContainerHighest: Color(0xFF1F2548), // Elevated Elements
      ),
      scaffoldBackgroundColor: Color(0xFF0A0E27),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF151B3F),
        foregroundColor: Color(0xFFF0F0F5),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Color(0xFF151B3F),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Color(0xFF2D5FFF).withOpacity(0.2), width: 1),
        ),
        shadowColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Color(0xFF151B3F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Color(0xFF2D5FFF).withOpacity(0.2), width: 1),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Color(0xFF1F2548),
        iconColor: Color(0xFF00D4FF),
        textColor: Color(0xFFF0F0F5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        color: Color(0xFF2D5FFF).withOpacity(0.15),
        thickness: 1,
        space: 16,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF151B3F),
        selectedItemColor: Color(0xFF00D4FF),
        unselectedItemColor: Colors.grey.shade600,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF1F2548),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Color(0xFF2D5FFF).withOpacity(0.3),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Color(0xFF2D5FFF).withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF00D4FF), width: 2),
        ),
        labelStyle: TextStyle(color: Colors.grey.shade400),
        hintStyle: TextStyle(color: Colors.grey.shade600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF2D5FFF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Color(0xFF00D4FF)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Color(0xFF1F2548),
        selectedColor: Color(0xFF2D5FFF),
        labelStyle: TextStyle(color: Color(0xFFF0F0F5)),
        secondaryLabelStyle: TextStyle(color: Colors.white),
        side: BorderSide(color: Color(0xFF2D5FFF).withOpacity(0.2)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF2D5FFF),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      brightness: Brightness.dark,
      useMaterial3: true,
    );
  }
}

class _AppInitializer extends StatefulWidget {
  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeUser();
  }

  Future<void> _initializeUser() async {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    await userViewModel.loadUserFromStorage();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        final userViewModel = Provider.of<UserViewModel>(context);

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF2D5FFF),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Yükleniyor...',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Color(0xFFFF4757), size: 64),
                  SizedBox(height: 16),
                  Text(
                    'Hata oluştu: ${snapshot.error ?? "Bilinmeyen hata"}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    child: Text('Yeniden Dene'),
                  ),
                ],
              ),
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (userViewModel.isLoggedIn) {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            Navigator.pushReplacementNamed(context, '/login');
          }
        });

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
