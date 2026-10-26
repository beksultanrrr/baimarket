import 'dart:io';

import 'package:dio/dio.dart';

import '../secure_token_storage.dart';
import '../services/app_logger.dart';
import '../urls.dart';

/// Результат регистрации токена — статус нужен экрану диагностики, поэтому
/// возвращаем его наружу, а не глотаем.
class PushTokenResult {
  const PushTokenResult({required this.ok, this.statusCode, this.body});
  final bool ok;
  final int? statusCode;
  final String? body;
}

/// Регистрация FCM-токена на бэкенде.
///
/// Свой `Dio`, а не общий `appDio`, по двум причинам:
/// * `appDio` без токена авторизации отклоняет запрос локально синтетическим
///   401 — вопрос «а существует ли вообще эта ручка» остался бы навсегда
///   замаскирован;
/// * `appDio` на настоящий 401 **разлогинивает пользователя**; бэкенд,
///   отвечающий 401 на регистрацию токена, выкидывал бы всех из аккаунта —
///   регрессия куда хуже тихих пушей.
class PushTokenRepository {
  PushTokenRepository({Dio? dio}) : _dio = dio ?? _build();

  final Dio _dio;

  /// ⚠️ Слэш на конце: во всём остальном коде его нет ни у одной из 18 ручек,
  /// а тут он исторически есть. Проверить у бэкенда — экран `/debug/push`
  /// теперь показывает статус-код, так что ответ виден с одного взгляда.
  static const path = 'firebase-token/';

  static Dio _build() {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          pushLog.api('→ ${options.method} ${options.uri.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          pushLog.api(
            '← ${response.statusCode} ${response.requestOptions.uri.path}',
            response.data?.toString(),
          );
          handler.next(response);
        },
        onError: (e, handler) {
          // Логируем громко и с телом: раньше 404 был полностью невидим —
          // сырой Dio без интерсептора плюс `print` в catch-all.
          pushLog.error(
            '← ${e.response?.statusCode ?? '-'} ${e.requestOptions.uri.path}',
            e.response?.data?.toString() ?? e.message,
          );
          handler.next(e);
        },
      ),
    );
    return dio;
  }

  Future<PushTokenResult> register(String token) async {
    try {
      final authToken = await getAuthToken();
      final response = await _dio.post(
        '$mainUrl$path',
        data: {
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
        options: Options(
          headers: {
            if (authToken != null) 'authorization': 'Bearer $authToken',
          },
          // Не бросать на 4xx — статус нужен вызывающему для решения о повторе.
          validateStatus: (_) => true,
        ),
      );
      final code = response.statusCode ?? 0;
      final ok = code >= 200 && code < 300;
      return PushTokenResult(
        ok: ok,
        statusCode: code,
        body: response.data?.toString(),
      );
    } on DioException catch (e) {
      return PushTokenResult(
        ok: false,
        statusCode: e.response?.statusCode,
        body: e.response?.data?.toString() ?? e.message,
      );
    } catch (e) {
      return PushTokenResult(ok: false, body: e.toString());
    }
  }

  /// Снятие регистрации при выходе.
  ///
  /// Ручки может не быть — тогда ответ просто логируется. Ждать её дольше
  /// нескольких секунд нельзя: логаут не должен подвисать.
  Future<PushTokenResult> unregister(String token) async {
    try {
      final authToken = await getAuthToken();
      final response = await _dio.delete(
        '$mainUrl$path',
        data: {'token': token},
        options: Options(
          headers: {
            if (authToken != null) 'authorization': 'Bearer $authToken',
          },
          validateStatus: (_) => true,
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      final code = response.statusCode ?? 0;
      return PushTokenResult(ok: code >= 200 && code < 300, statusCode: code);
    } catch (e) {
      pushLog.warn('unregister failed', e.toString());
      return PushTokenResult(ok: false, body: e.toString());
    }
  }
}
