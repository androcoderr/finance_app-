// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyC1u1clKcqvbi4mGJvAaUP6bs_FD1xSeGw", // ✅ Buraya yapıştır
    appId: "1:800544380029:android:d9b395d5c94af182964d14", // com.finanscepte.app
    messagingSenderId: "800544380029",
    projectId: "test-borsa-2fa",
    storageBucket: "test-borsa-2fa.firebasestorage.app", // ✅ Bu storage bucket
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyCAnnFhQ4dr-lJt1Spk8-VzkMR1khG54cg",
    appId: "1:800544380029:ios:187d8944b919ed29964d14", // com.finanscepte.app
    messagingSenderId: "800544380029",
    projectId: "test-borsa-2fa",
    storageBucket: "test-borsa-2fa.firebasestorage.app",
    iosBundleId: "com.finanscepte.app",
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyC1u1clKcqvbi4mGJvAaUP6bs_FD1xSeGw", // Aynı API key
    appId: "1:800544380029:web:xxxxxxxxxx", // Web ekleyince değişecek
    messagingSenderId: "800544380029",
    projectId: "test-borsa-2fa",
    authDomain: "test-borsa-2fa.firebaseapp.com",
    storageBucket: "test-borsa-2fa.firebasestorage.app",
    measurementId: "G-XXXXXXXXXX", // Web ekleyince gelecek
  );
}
