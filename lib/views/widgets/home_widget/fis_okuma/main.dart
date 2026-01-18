// main.dart

import 'package:flutter/material.dart';
// Görüntü ve Ses Paketleri
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:intl/intl.dart';

import 'gemine_classifier.dart'; // Tarih formatlama için

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ReceiptApp());
}

class ReceiptApp extends StatelessWidget {
  const ReceiptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Hibrit Fiş Kayıt Sistemi (Gemini)',
      home: Placeholder(),
    );
  }
}
