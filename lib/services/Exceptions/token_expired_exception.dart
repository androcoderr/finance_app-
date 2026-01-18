class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException([this.message = 'Token süresi doldu']);
  @override
  String toString() => message;
}
