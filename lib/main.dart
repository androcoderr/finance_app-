import 'dart:async';
import 'package:test_borsa/utils/feature_flags.dart';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
import 'services/bill_reminder_service.dart';
import 'theme/app_theme.dart';
import 'views/widgets/ui/brand.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("--- Arka Planda Mesaj Geldi (Handler) ---");
  FirebaseService.backgroundMessageHandler(message);
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

    // Çökme raporları (yalnızca yayın sürümünde gönderilir). Kişisel/finansal
    // veri eklenmez: kullanıcı kimliği, e-posta, tutar vb. gönderilmez.
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = crashlytics.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Bildirim altyapısı yalnızca sunucudan bildirim gelen özellikler (AI)
    // açıkken kurulur; v1'de FCM token alınmaz ve sunucuya gönderilmez
    if (kNotificationsEnabled) {
      final firebaseService = FirebaseService.instance;
      await firebaseService.requestNotificationPermissions();
      await firebaseService.getFCMToken();

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        FirebaseService.foregroundMessageHandler(message);
        if (message.data['navigate'] == 'notifications') {
          Future.microtask(() {
            navigatorKey.currentState?.pushNamed("/notifications");
          });
        }
      });
    }

    print('✅ Messaging listeners hazır.');
  } catch (e) {
    print('❌ Firebase init hata: $e');
  }

  await initializeDateFormatting('tr_TR', null);

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Fatura hatırlatmaları (yerel); bildirime dokununca Faturalar açılır
  await BillReminders.init(
    onOpen: () => navigatorKey.currentState?.pushNamed('/bills'),
  );

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
    _openBills = await BillReminders.launchedFromReminder();
  }

  bool _openBills = false;

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
            // Uygulama bir fatura hatırlatmasına dokunularak açıldıysa
            if (_openBills) {
              _openBills = false;
              navigatorKey.currentState?.pushNamed('/bills');
            }
          } else {
            Navigator.pushReplacementNamed(context, '/login');
          }
        });

        return const BrandSplash();
      },
    );
  }
}
