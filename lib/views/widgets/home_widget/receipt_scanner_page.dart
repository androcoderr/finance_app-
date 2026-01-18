import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../models/transaction_model.dart';
import '../../../services/transaction_service.dart';
import '../../../view_model/user_view_model.dart';
import 'fis_okuma/gemine_classifier.dart';
import '../../../services/category_service.dart';
import '../../../models/category_model.dart';

enum InputMethod { camera, gallery, voice }

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});
  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  String _recognizedText = '';
  String _assignedCategory = '';
  double _detectedAmount = 0.0;
  String _detectedDate = '';
  String _detectedDescription = '';
  bool _isProcessing = false;
  bool _showConfirmation = false;

  final GeminiReceiptClassifier _geminiClassifier = GeminiReceiptClassifier();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TransactionService _transactionService = TransactionService();
  bool _isListening = false;
  String _currentSpeechText = '';
  bool _speechAvailable = false;

  List<Map<String, String>> _transactionRecords = [];
  List<Category> _availableCategories = [];

  @override
  void initState() {
    super.initState();
    _initSpeechRecognizer();
    _initData();
  }

  Future<void> _initData() async {
    await _loadCategories();
    _loadInitialTransactions();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await CategoryService.getCategories();
      if (mounted) {
        setState(() {
          _availableCategories = categories;
        });
      }
    } catch (e) {
      print("Error loading categories: $e");
    }
  }

  String _getCategoryName(String id) {
    if (_availableCategories.isEmpty) return id;
    try {
      final category = _availableCategories.firstWhere((c) => c.id == id);
      return category.name;
    } catch (e) {
      return id;
    }
  }

  void _loadInitialTransactions() async {
    // Sayfa açıldığında mevcut işlemleri API'den çekebiliriz
    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      if (userViewModel.currentUser != null &&
          userViewModel.authToken != null) {
        final transactions = await _transactionService.getTransactions(
          userViewModel.currentUser!.id,
          userViewModel.authToken!,
        );
        if (mounted) {
          setState(() {
            _transactionRecords = transactions
                .map(
                  (t) => {
                    'id': t.id ?? '',
                    'category': _getCategoryName(t.categoryId),
                    'date': DateFormat('dd/MM/yyyy HH:mm').format(t.date),
                    'amount': t.amount.toStringAsFixed(2),
                    'raw_text_preview': t.description,
                  },
                )
                .toList();
          });
        }
      }
    } catch (e) {
      print("Error loading transactions: $e");
    }
  }

  void _initSpeechRecognizer() async {
    try {
      var micStatus = await Permission.microphone.status;

      // Explicitly request if not granted
      if (!micStatus.isGranted) {
        micStatus = await Permission.microphone.request();
      }

      if (micStatus.isGranted) {
        bool available = await _speech.initialize(
          onError: (val) {
            if (mounted) {
              setState(() {
                _isListening = false;
                _isProcessing = false;
                print('Speech Error: ${val.errorMsg}');
              });
            }
          },
          onStatus: (val) {
            if (mounted) {
              if (val == 'notListening' || val == 'done') {
                setState(() {
                  _isListening = false;
                });
              }
            }
          },
        );

        if (mounted) {
          setState(() {
            _speechAvailable = available;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _speechAvailable = false;
            _recognizedText =
                'Mikrofon izni verilmediği için ses özelliği kapalı.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _speechAvailable = false;
          print("Speech initialization error: $e");
        });
      }
    }
  }

  Future<InputMethod?> _showInputMethodDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showModalBottomSheet<InputMethod>(
      context: context,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Fiş Ekleme Yöntemi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[800],
                  ),
                ),
                SizedBox(height: 20),
                _buildMethodTile(
                  icon: Icons.camera_alt,
                  title: 'Kameradan Çek',
                  subtitle: 'Fişi kamera ile tara',
                  color: Colors.blue[600]!,
                  onTap: () => Navigator.pop(context, InputMethod.camera),
                  isDark: isDark,
                ),
                _buildMethodTile(
                  icon: Icons.photo_library,
                  title: 'Galeriden Seç',
                  subtitle: 'Kayıtlı fotoğraf seç',
                  color: Colors.purple[600]!,
                  onTap: () => Navigator.pop(context, InputMethod.gallery),
                  isDark: isDark,
                ),
                _buildMethodTile(
                  icon: Icons.mic,
                  title: 'Sesli Giriş',
                  subtitle: _speechAvailable
                      ? 'Sesle fiş bilgisi ekle'
                      : 'Servis kullanılamıyor',
                  color: _speechAvailable
                      ? Colors.orange[600]!
                      : Colors.grey[400]!,
                  onTap: _speechAvailable
                      ? () => Navigator.pop(context, InputMethod.voice)
                      : null,
                  isDark: isDark,
                  enabled: _speechAvailable,
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMethodTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
    required bool isDark,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: enabled
                  ? (isDark ? Colors.grey[850] : Colors.grey[50])
                  : (isDark ? Colors.grey[900] : Colors.grey[200]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: enabled ? color.withOpacity(0.3) : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: enabled ? color.withOpacity(0.1) : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: enabled ? color : Colors.grey,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: enabled
                              ? (isDark ? Colors.white : Colors.grey[800])
                              : Colors.grey[500],
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: enabled ? Colors.grey[600] : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: enabled ? Colors.grey[400] : Colors.grey[300],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _processGeminiAnalysis(String rawText) async {
    if (rawText.isEmpty || rawText.trim().isEmpty) {
      setState(() {
        _isProcessing = false;
        _recognizedText = 'Hiçbir ses algılanmadı. Lütfen tekrar deneyin.';
      });
      return;
    }

    final String currentDate = DateFormat(
      'dd/MM/yyyy HH:mm:ss',
    ).format(DateTime.now());

    setState(() {
      _isProcessing = true;
      _recognizedText = rawText;
    });

    final Map<String, dynamic>? analysisResult = await _geminiClassifier
        .classifyAndParse(rawText);

    if (analysisResult != null) {
      final String category = analysisResult['category'] ?? 'Diğer';
      final double amount = analysisResult['amount']?.toDouble() ?? 0.0;
      final String description = analysisResult['description'] ?? rawText;

      setState(() {
        _assignedCategory = category;
        _detectedAmount = amount;
        _detectedDate = currentDate;
        _detectedDescription = description;
        _isProcessing = false;
        _isListening = false;
        _showConfirmation = true;
      });
    } else {
      setState(() {
        _assignedCategory = 'API Analiz Edemedi';
        _detectedDate = currentDate;
        _detectedAmount = 0.0;
        _detectedDescription =
            'API veya ağ hatası nedeniyle analiz başarısız oldu.';
        _isProcessing = false;
        _isListening = false;
      });
    }
  }

  Future<void> _handleInput() async {
    final InputMethod? method = await _showInputMethodDialog(context);
    String rawTextFromInput = '';

    if (method == null) return;

    setState(() {
      _isProcessing = true;
      _recognizedText = 'İşleniyor...';
      _currentSpeechText = '';
      _assignedCategory = '';
      _detectedAmount = 0.0;
      _detectedDate = '';
      _detectedDescription = '';
      _showConfirmation = false;
    });

    try {
      if (method == InputMethod.camera) {
        var status = await Permission.camera.status;
        if (!status.isGranted) {
          status = await Permission.camera.request();
          if (!status.isGranted) {
            throw Exception("Kamera izni reddedildi.");
          }
        }

        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(source: ImageSource.camera);

        if (image == null) throw Exception("Görüntü seçimi iptal edildi.");
        await _processImage(image.path);
      } else if (method == InputMethod.gallery) {
        // Galeri izni kontrolü
        if (Platform.isAndroid) {
          final status = await Permission.photos.status;
          if (status.isDenied) {
            await Permission.photos.request();
          }
        }

        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
        );

        if (image == null) throw Exception("Görüntü seçimi iptal edildi.");
        await _processImage(image.path);
      } else if (method == InputMethod.voice) {
        var micStatus = await Permission.microphone.status;
        if (!micStatus.isGranted) {
          micStatus = await Permission.microphone.request();
          if (!micStatus.isGranted) {
            throw Exception("Mikrofon izni reddedildi!");
          }
        }

        if (!_speech.isAvailable) {
          bool available = await _speech.initialize(
            onError: (val) => print('Init Error: ${val.errorMsg}'),
            onStatus: (val) => print('Init Status: $val'),
          );
          if (!available) {
            throw Exception("Ses tanıma servisi cihazda kullanılamıyor.");
          }
        }

        if (_isListening) {
          await _speech.stop();
          setState(() {
            _isListening = false;
            _isProcessing = false;
          });
          return;
        }

        setState(() {
          _isListening = true;
          _recognizedText = 'Dinleniyor...';
          _currentSpeechText = '';
        });

        await _speech.listen(
          localeId: "tr_TR",
          onResult: (result) {
            setState(() {
              _recognizedText = result.recognizedWords.isNotEmpty
                  ? result.recognizedWords
                  : 'Dinleniyor...';
              _currentSpeechText = result.recognizedWords;
            });

            if (result.finalResult && result.recognizedWords.isNotEmpty) {
              _speech.stop();
              _processGeminiAnalysis(result.recognizedWords);
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          cancelOnError: true,
          partialResults: true,
        );
      }
    } catch (e) {
      setState(() {
        _recognizedText = 'Hata: ${e.toString()}';
        _assignedCategory = 'Başarısız';
        _isProcessing = false;
        _isListening = false;
      });
    }
  }

  Future<void> _processImage(String path) async {
    final InputImage inputImage = InputImage.fromFilePath(path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedResult = await textRecognizer.processImage(
      inputImage,
    );
    String text = recognizedResult.text;
    textRecognizer.close();
    await _processGeminiAnalysis(text);
  }

  Future<void> _confirmAndSave() async {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);

    if (userViewModel.currentUser == null || userViewModel.authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Oturum bilgisi bulunamadı. Lütfen tekrar giriş yapın.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    String categoryIdToUse = _assignedCategory;

    // Try to find the category by name
    try {
      if (_availableCategories.isNotEmpty) {
        final matchingCategory = _availableCategories.firstWhere(
          (c) => c.name.toLowerCase() == _assignedCategory.toLowerCase(),
        );
        categoryIdToUse = matchingCategory.id;
      }
    } catch (e) {
      // Not found, try to find 'Diğer'
      try {
        final otherCategory = _availableCategories.firstWhere(
          (c) => c.name == 'Diğer',
        );
        categoryIdToUse = otherCategory.id;
      } catch (e) {
        print(
          "Category mapping failed for $_assignedCategory and fallback 'Diğer'",
        );
      }
    }

    final newTransaction = TransactionModel(
      userId: userViewModel.currentUser!.id,
      amount: _detectedAmount,
      categoryId: categoryIdToUse,
      description: _detectedDescription,
      date: DateTime.now(),
      type: TransactionType.expense,
    );

    final success = await _transactionService.addTransaction(
      newTransaction,
      userViewModel.authToken!,
      context: context,
    );

    if (success) {
      setState(() {
        _showConfirmation = false;
        _isProcessing = false;
        _recognizedText = '';
        _assignedCategory = '';
        _detectedAmount = 0.0;
        _detectedDate = '';
        _detectedDescription = '';
      });
      // Listeyi yenile
      _loadInitialTransactions();
    } else {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _cancelSave() {
    setState(() {
      _showConfirmation = false;
      _recognizedText = '';
      _assignedCategory = '';
      _detectedAmount = 0.0;
      _detectedDate = '';
      _detectedDescription = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Fiş Kayıt Sistemi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _showConfirmation
          ? _buildConfirmationView(isDark)
          : _buildMainView(isDark),
      floatingActionButton: !_showConfirmation
          ? FloatingActionButton.extended(
              onPressed: (_isProcessing && !_isListening) ? null : _handleInput,
              label: Text(
                _isListening
                    ? 'Durdur'
                    : (_isProcessing ? 'İşleniyor...' : 'Fiş Ekle'),
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              icon: _isListening
                  ? Icon(Icons.stop)
                  : (_isProcessing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Icon(Icons.add_photo_alternate)),
              backgroundColor: _isListening
                  ? Colors.red[600]
                  : ((_isProcessing && !_isListening)
                        ? Colors.grey
                        : Colors.blue[600]),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildMainView(bool isDark) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(Duration(milliseconds: 500));
        _loadInitialTransactions(); // Refresh'te listeyi yenile
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isListening) _buildListeningIndicator(isDark),
            if (_isProcessing && !_isListening)
              _buildProcessingIndicator(isDark),
            if (_recognizedText.isNotEmpty && !_isProcessing)
              _buildRecognizedTextCard(isDark),
            SizedBox(height: 20),
            _buildSectionTitle('Son İşlemler', isDark),
            SizedBox(height: 12),
            _buildTransactionsList(isDark),
            SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationView(bool isDark) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Tespit Edilen Bilgiler', isDark),
            SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.category_outlined,
              title: 'Kategori',
              value: _assignedCategory,
              color: Colors.blue[600]!,
              isDark: isDark,
            ),
            SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.payments_outlined,
              title: 'Tutar',
              value: '${_detectedAmount.toStringAsFixed(2)} TL',
              color: Colors.green[600]!,
              isDark: isDark,
            ),
            SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.calendar_today_outlined,
              title: 'Tarih',
              value: _detectedDate,
              color: Colors.orange[600]!,
              isDark: isDark,
            ),
            SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.description_outlined,
              title: 'Açıklama',
              value: _detectedDescription,
              color: Colors.purple[600]!,
              isDark: isDark,
            ),
            SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _cancelSave,
                    icon: Icon(Icons.close),
                    label: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('İptal', style: TextStyle(fontSize: 15)),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.red[400]!, width: 1.5),
                      foregroundColor: Colors.red[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _confirmAndSave,
                    icon: Icon(Icons.check_circle_outline),
                    label: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('Kaydet', style: TextStyle(fontSize: 15)),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildListeningIndicator(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.red[400]!, Colors.red[600]!]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.mic, color: Colors.white, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dinleniyor...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Lütfen yüksek sesle konuşun',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingIndicator(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Row(
        children: [
          CircularProgressIndicator(strokeWidth: 3),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Analiz ediliyor...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecognizedTextCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.text_fields, color: Colors.blue[600], size: 20),
              SizedBox(width: 8),
              Text(
                'Okunan Metin',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            _recognizedText,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.grey[800],
      ),
    );
  }

  Widget _buildTransactionsList(bool isDark) {
    if (_transactionRecords.isEmpty) {
      return Container(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                'Henüz kayıt bulunmuyor',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Fiş ekleyerek başlayın',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _transactionRecords.length,
      itemBuilder: (context, index) {
        final record = _transactionRecords[index];
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(12),
            leading: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[600]!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.receipt, color: Colors.blue[600], size: 24),
            ),
            title: Text(
              '${record['category']} - ${record['amount']} TL',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 6),
                      Text(
                        record['date']!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    record['raw_text_preview']!,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}
