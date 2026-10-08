// `package:http` yerine geçer: kendi backend'imize giden ve 401 (oturum süresi
// doldu) alan istekleri, kayıtlı refresh_token ile yeni access_token alıp bir
// kez tekrar dener. Kullanım: import '.../api_http.dart' as http;
// Mevcut `http.get(...)`, `http.Response` vb. kodlar olduğu gibi çalışır.
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'BaseService.dart';

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
  final response = await first();
  if (response.statusCode != 401 || !_isRefreshable(url, headers)) {
    return response;
  }

  final newToken = await _refreshAccessToken();
  if (newToken == null) return response; // Yenilenemedi: eski davranış (giriş ekranı)

  final newHeaders = Map<String, String>.from(headers!)
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

// Aynı anda birden çok istek 401 alırsa tek bir yenileme yapılır
Future<String?>? _inFlight;

Future<String?> _refreshAccessToken() {
  return _inFlight ??= _doRefresh().whenComplete(() => _inFlight = null);
}

Future<String?> _doRefresh() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final res = await http.post(
      Uri.parse('${BaseService.baseUrl}/auth/refresh'),
      headers: {'Authorization': 'Bearer $refreshToken'},
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return null;

    final token = jsonDecode(res.body)['access_token'] as String?;
    if (token == null || token.isEmpty) return null;
    await prefs.setString('access_token', token);
    onAccessTokenRefreshed?.call(token);
    return token;
  } catch (_) {
    return null;
  }
}
