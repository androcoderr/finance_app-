import 'package:flutter/material.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    String errorText = error.toString();

    // Strip "Exception: " prefix
    if (errorText.startsWith('Exception: ')) {
      errorText = errorText.replaceFirst('Exception: ', '');
    }

    // Lowercase for easier matching
    final lowerError = errorText.toLowerCase();

    // Network Errors
    if (lowerError.contains('socketexception') || 
        lowerError.contains('connection refused') ||
        lowerError.contains('connection timed out') ||
        lowerError.contains('network is unreachable') ||
        lowerError.contains('clientexception') ||
        lowerError.contains('failed to connect')) {
      return 'Sunucuya bağlanılamadı. İnternet bağlantınızı kontrol edin.';
    } else if (lowerError.contains('xmlhttprequest')) {
      return 'İnternet bağlantısı hatası.';
    } else if (lowerError.contains('timeout')) {
      return 'İşlem zaman aşımına uğradı. Lütfen tekrar deneyin.';
    }

    // Auth Errors
    else if (lowerError.contains('401') || lowerError.contains('unauthorized') || lowerError.contains('yetkisiz')) {
      return 'Oturum süreniz doldu veya yetkisiz işlem. Lütfen tekrar giriş yapın.';
    } else if (lowerError.contains('token expired') || lowerError.contains('expired')) {
      return 'Oturum süreniz doldu. Lütfen tekrar giriş yapın.';
    } else if (lowerError.contains('403') || lowerError.contains('forbidden')) {
      return 'Bu işlem için yetkiniz yok.';
    } else if (lowerError.contains('user-not-found') || lowerError.contains('user not found')) {
      return 'Kullanıcı bulunamadı.';
    } else if (lowerError.contains('wrong-password') || lowerError.contains('wrong password') || lowerError.contains('invalid password')) {
      return 'Hatalı şifre.';
    } else if (lowerError.contains('invalid credentials') || lowerError.contains('bad credentials')) {
      return 'E-posta veya şifre hatalı.';
    } else if (lowerError.contains('email-already-in-use') || lowerError.contains('email already exists')) {
      return 'Bu e-posta adresi zaten kullanımda.';
    } else if (lowerError.contains('weak-password')) {
      return 'Şifreniz çok zayıf. Daha güçlü bir şifre seçin.';
    } else if (lowerError.contains('invalid-email') || lowerError.contains('badly formatted')) {
      return 'Geçersiz e-posta adresi formatı.';
    } else if (lowerError.contains('requires_2fa')) {
      return 'İki faktörlü doğrulama gerekli.';
    }

    // Server Errors
    else if (lowerError.contains('500') || lowerError.contains('internal server error')) {
      return 'Sunucu hatası oluştu. Lütfen daha sonra tekrar deneyin.';
    } else if (lowerError.contains('502') || lowerError.contains('bad gateway')) {
      return 'Sunucu şu anda hizmet veremiyor (502).';
    } else if (lowerError.contains('503') || lowerError.contains('service unavailable')) {
      return 'Sunucu şu anda meşgul (503).';
    } else if (lowerError.contains('404') || lowerError.contains('not found')) {
      return 'İstenen kaynak bulunamadı (404).';
    } else if (lowerError.contains('too-many-requests')) {
      return 'Çok fazla deneme yaptınız. Lütfen bir süre bekleyin.';
    }

    // Data Errors
    else if (lowerError.contains('format')) {
      return 'Veri formatı hatası oluştu.';
    }

    // Fallback for unknown errors
    // If the error message is too long (likely a stack trace or raw html), show generic message
    if (errorText.length > 150) {
      return 'Beklenmedik bir hata oluştu.';
    }

    return errorText;
  }

  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final message = getErrorMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
