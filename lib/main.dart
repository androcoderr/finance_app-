import 'dart:async';
import 'package:test_borsa/utils/feature_flags.dart';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'services/app_update_service.dart';
import 'theme/app_theme.dart';
import 'views/widgets/ui/brand.dart';

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

// Release sürümde print çıktıları (token, kullanıcı verisi vb.) cihaz loglarına yazılmasın
void main() {
  runZoned(
    _main,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        if (kDebugMode) parent.print(zone, line);
      },
    ),
  );
}

Future<void> _main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Uygulama yalnızca dik kullanılır (yan çevrilince ekranlar bozulmasın)
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase Core başlatıldı.');

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final firebaseService = FirebaseService.instance;
    firebaseService.on2faRequest = (title, body, sessionToken) =>
        _show2faConfirmationDialog(
          title: title,
          body: body,
          sessionToken: sessionToken,
        );

    if (kNotificationsEnabled) {
      await firebaseService.requestNotificationPermissions();
    }
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
            // Sistem metinleri (tarih seçici, kopyala/yapıştır vb.) Türkçe
            locale: const Locale('tr', 'TR'),
            supportedLocales: const [Locale('tr', 'TR')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            // Çok büyük sistem yazı boyutunda (Android'de 2x'e kadar) ekranlar
            // taşmasın: en fazla 1.3x büyütülür
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(
                  textScaler: mq.textScaler.clamp(maxScaleFactor: 1.3),
                ),
                child: child!,
              );
            },
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

  AppConfig? _config;

  Future<void> _initializeUser() async {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    await AppUpdateService.init();
    // Sürüm kontrolü oturum yüklemesiyle paralel; ağ hatasında null döner
    final config = AppUpdateService.fetchConfig();
    await userViewModel.loadUserFromStorage();
    _config = await config;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        final userViewModel = Provider.of<UserViewModel>(context);

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const BrandSplash();
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
          final config = _config;
          if (config != null && config.updateRequired) {
            AppUpdateService.showForcedUpdate(
              message: config.message,
              storeUrl: config.storeUrl,
            );
            return;
          }
          if (config != null && config.updateAvailable) {
            Future.delayed(const Duration(milliseconds: 600),
                () => AppUpdateService.showOptionalUpdate(config));
          }
          if (userViewModel.isLoggedIn) {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            Navigator.pushReplacementNamed(context, '/login');
          }
        });

        return const BrandSplash();
      },
    );
  }
}
