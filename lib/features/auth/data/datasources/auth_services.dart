import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/secure_token_storage.dart';
import '../../../../core/urls.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthServices implements AuthRepository {
  final Dio _dio = Dio();
  @override
  Future<bool> sendOtp({required String phoneNumber}) async {
    final url = mainUrl;
    String finalUrl = '${url}auth/otp/request';
    debugPrint('🌐 POST $finalUrl');
    debugPrint('🌐 body: {"phoneNumber": "$phoneNumber"}');
    try {
      final response = await _dio.post(
        finalUrl,
        data: jsonEncode({"phoneNumber": phoneNumber}),
      );
      debugPrint('🌐 response status: ${response.statusCode}');
      debugPrint('🌐 response data: ${response.data}');
      if (response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('🌐 ❌ sendOtp error: $e');
      return false;
    }
  }

  @override
  Future<bool> verifyOtp({
    required String phoneNumber,
    required String code,
  }) async {
    final url = mainUrl;
    String finalUrl = '${url}auth/otp/confirm';
    try {
      final response = await _dio.post(
        finalUrl,
        data: jsonEncode({"phoneNumber": phoneNumber, "code": code}),
      );
      if (response.statusCode == 201) {
        await setAuthToken(response.data['accessToken']);
        // Refresh приходит тем же ответом — раньше мы его молча выбрасывали, и
        // сессия жила ровно до истечения access-токена. Читаем мягко: если
        // бэкенд его вдруг не прислал, вход всё равно должен состояться.
        final refreshToken = response.data['refreshToken'] as String?;
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await setRefreshToken(refreshToken);
        } else {
          debugPrint('🌐 ⚠️ verifyOtp: refreshToken отсутствует в ответе');
        }
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}

/// Отзыв refresh-токена на сервере: `POST /auth/logout` с телом
/// `{ "refreshToken": "..." }`.
///
/// Живёт вне [AuthServices] и вне [AuthRepository] намеренно: интерфейс
/// описывает только вход, а звать отзыв нужно из кубита перед стиранием
/// хранилища. Без этого «выход» был чисто локальным, и токен оставался
/// действительным на бэкенде все 90 дней.
///
/// Ходит на своём чистом `Dio` — общий `appDio` на 401 полез бы рефрешиться и
/// разлогинивать, чего при выходе уже не требуется. Ошибки глушатся: выход не
/// должен падать из-за сети, локальные токены сотрёт вызывающая сторона.
Future<void> revokeRefreshToken() async {
  final refreshToken = await getRefreshToken();
  if (refreshToken == null || refreshToken.isEmpty) return;
  try {
    final response = await Dio().post(
      authLogoutUrl,
      data: {'refreshToken': refreshToken},
    );
    debugPrint('🌐 logout status: ${response.statusCode}');
  } catch (e) {
    debugPrint('🌐 ❌ logout error: $e');
  }
}
