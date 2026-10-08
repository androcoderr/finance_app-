import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiReceiptClassifier {
  // 🔑 API Anahtarınız buraya yerleştirilmiştir.
  final String _apiKey = const String.fromEnvironment('GEMINI_API_KEY');

  // Model URL'si
  final String _apiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";

  // Tüm 34 kategori listesi
  final List<String> _validCategories = [
    'Market',
    'Alışveriş',
    'Yiyecek',
    'Telefon',
    'Eğlence',
    'Eğitim',
    'Güzellik',
    'Spor',
    'Sosyal',
    'Ulaşım',
    'Giyim',
    'Araba',
    'İçecekler',
    'Sigara',
    'Elektronik',
    'Seyahat',
    'Sağlık',
    'Pet',
    'Onarım',
    'Konut',
    'Mobilya',
    'Hediyeler',
    'Bağış',
    'Oyun',
    'Atıştırmalık',
    'Çocuk',
    'Diğer',
    'Maaş',
    'Prim',
    'Hediye',
    'Yatırım',
    'Ek Gelir',
    'Faiz',
  ];

  Future<Map<String, dynamic>?> classifyAndParse(String rawText) async {
    final String categoryList = _validCategories.join(', ');

    // 1. PROMPT (Talimat) oluşturma
    final String prompt =
        '''
      Aşağıdaki fiş/harcama metnini analiz et.
      1. Kategoriyi, SADECE [$categoryList] listesinden seç.
      2. Metindeki en büyük geçerli tutarı TL cinsinden ondalıklı sayı olarak bul ve 'amount' alanına yaz (Örn: 120.50).
      3. Metnin kısa bir özetini (Description) oluştur ve 'description' alanına yaz.
      4. Sonucu sadece ve kesinlikle JSON formatında döndür. JSON bloğu dışında başka metin veya açıklama yazma.

      [FİŞ METNİ]: "$rawText"
    ''';

    // 2. İstek gövdesini (Body) oluşturma (Düzeltilmiş Format)
    final Map<String, dynamic> requestBody = {
      "contents": [
        {
          "parts": [
            {"text": prompt},
          ],
        },
      ],

      // CONFIGURATION (AYARLAR) BLOĞU:
      // Doğrudan 'config' yerine, 'generationConfig' ve 'tools' blokları kullanılır.
      // Yapılandırılmış Çıktı (responseSchema) için 'tools' içinde 'function_call' veya
      // doğrudan 'config' (Gemini-1.5 için) kullanılırdı.
      //
      // Ancak en güvenli yöntem, standart parametreleri kullanmaktır:
      "generationConfig": {
        "temperature": 0.0,
        "responseMimeType": "application/json",
        "responseSchema": {
          "type": "object",
          "properties": {
            "category": {"type": "string"},
            "amount": {"type": "number"},
            "description": {"type": "string"},
          },
          "required": ["category", "amount", "description"],
        },
      },
    };

    try {
      // 3. API çağrısı yapma
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Hata kontrolü: Eğer "error" alanı varsa, kotayı veya anahtarı kontrol et
        if (jsonResponse.containsKey('error')) {
          print("API Hata (Gemini): ${jsonResponse['error']['message']}");
          return null;
        }

        // Gemini yapısına göre sonucu al
        final String contentText =
            jsonResponse['candidates'][0]['content']['parts'][0]['text'];

        // JSON stringini Dart Map'e çevir
        return jsonDecode(contentText);
      } else {
        print("API Hatası: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Kritik İstek Hatası: $e");
      return null;
    }
  }
}
