// `package:http` yerine geçer: kendi backend'imize giden ve 401 (oturum süresi
// doldu) alan istekleri, kayıtlı refresh_token ile yeni access_token alıp bir
// kez tekrar dener. Kullanım: import '.../api_http.dart' as http;
import 'package:test_borsa/services/token_storage.dart';
// Mevcut `http.get(...)`, `http.Response` vb. kodlar olduğu gibi çalışır.
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'BaseService.dart';
import 'app_update_service.dart';

export 'package:http/http.dart' hide get, post, put, patch, delete;

Future<http.Response> get(Uri url, {Map<String, String>? headers}) =>
    _send(() => http.get(url, headers: headers), url, headers,
        (h) => http.get(url, headers: h));

Future<http.Response> post(Uri url,
        {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    _send(() => http.post(url, headers: headers, body: body, encoding: encoding),
        url, headers,
        (h) => http.post(url, headers: h, body: body, encoding: encoding));

Future<http.Response> put(Uri url,
        {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    _send(() => http.put(url, headers: headers, body: body, encoding: encoding),
        url, headers,
        (h) => http.put(url, headers: h, body: body, encoding: encoding));

Future<http.Response> patch(Uri url,
        {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    _send(
        () => http.patch(url, headers: headers, body: body, encoding: encoding),
        url, headers,
        (h) => http.patch(url, headers: h, body: body, encoding: encoding));

Future<http.Response> delete(Uri url,
        {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    _send(
        () => http.delete(url, headers: headers, body: body, encoding: encoding),
        url, headers,
        (h) => http.delete(url, headers: h, body: body, encoding: encoding));

Future<http.Response> _send(
  Future<http.Response> Function() first,
  Uri url,
  Map<String, String>? headers,
  Future<http.Response> Function(Map<String, String>) retry,
) async {
  final ours = url.toString().startsWith(BaseService.baseUrl);
  // Kendi sunucumuza giden isteklere sürüm kodu eklenir
  final sent = ours ? {...?headers, ...AppUpdateService.header} : headers;
  final response = ours ? await retry(sent!) : await first();

  // 426: bu sürüm artık desteklenmiyor
  if (ours && response.statusCode == 426) {
    String? storeUrl;
    try {
      storeUrl = jsonDecode(response.body)['store_url'] as String?;
    } catch (_) {}
    AppUpdateService.showForcedUpdate(storeUrl: storeUrl);
    return response;
  }

  if (response.statusCode != 401 || !_isRefreshable(url, sent)) {
    return response;
  }

  final newToken = await _refreshAccessToken();
  if (newToken == null) return response; // Yenilenemedi: eski davranış (giriş ekranı)

  final newHeaders = Map<String, String>.from(sent!)
    ..removeWhere((k, _) => k.toLowerCase() == 'authorization')
    ..['Authorization'] = 'Bearer $newToken';
  return retry(newHeaders);
}

bool _isRefreshable(Uri url, Map<String, String>? headers) {
  if (headers == null) return false;
  final hasAuth = headers.keys.any((k) => k.toLowerCase() == 'authorization');
  return hasAuth &&
      url.toString().startsWith(BaseService.baseUrl) &&
      !url.path.endsWith('/auth/refresh') &&
      !url.path.endsWith('/auth/login');
}

/// Token yenilendiğinde çağrılır (UserViewModel bellekteki token'ı günceller)
void Function(String accessToken)? onAccessTokenRefreshed;

/// Refresh token değiştiğinde çağrılır (ör. şifre değişince sunucu yeni çift verir)
void Function(String refreshToken)? onRefreshTokenChanged;

/// Sunucunun verdiği yeni token çiftini kaydeder (şifre değişince eskiler geçersizleşir)
Future<void> saveTokens(String accessToken, String refreshToken) async {
  await TokenStorage.saveAccess(accessToken);
  await TokenStorage.saveRefresh(refreshToken);
  onAccessTokenRefreshed?.call(accessToken);
  onRefreshTokenChanged?.call(refreshToken);
}

// Aynı anda birden çok istek 401 alırsa tek bir yenileme yapılır
Future<String?>? _inFlight;

Future<String?> _refreshAccessToken() {
  return _inFlight ??= _doRefresh().whenComplete(() => _inFlight = null);
}

Future<String?> _doRefresh() async {
  try {
    final refreshToken = await TokenStorage.refresh();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final res = await http.post(
      Uri.parse('${BaseService.baseUrl}/auth/refresh'),
      headers: {'Authorization': 'Bearer $refreshToken', ...AppUpdateService.header},
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return null;

    final token = jsonDecode(res.body)['access_token'] as String?;
    if (token == null || token.isEmpty) return null;
    await TokenStorage.saveAccess(token);
    onAccessTokenRefreshed?.call(token);
    return token;
  } catch (_) {
    return null;
  }
}
