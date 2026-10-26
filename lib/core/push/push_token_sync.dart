import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../secure_token_storage.dart';
import '../services/app_logger.dart';
import 'push_registration_store.dart';
import 'push_token_repository.dart';

enum PushSyncTrigger { start, login, refresh, resume, manual }

/// Единственный владелец инварианта «на сервере лежит актуальный токен этого
/// устройства».
///
/// Что было сломано до этого: токен отправлялся ровно один раз — при старте
/// процесса, **до** логина. Если авторизации на тот момент не было, токен
/// молча выбрасывался, а логин ничего не перезапускал. В результате
/// пользователь становился недостижим до следующего холодного старта.
class PushTokenSync {
  PushTokenSync._();

  static final _store = PushRegistrationStore();
  static PushTokenRepository _repository = PushTokenRepository();

  /// Для тестов.
  static void overrideRepository(PushTokenRepository repository) {
    _repository = repository;
  }

  static Future<void>? _inFlight;
  static Timer? _retryTimer;
  static int _retryAttempt = 0;

  static const _retryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 8),
    Duration(seconds: 30),
    Duration(seconds: 120),
  ];

  /// Токен считается свежим неделю. Потолок нужен, чтобы потеря строки на
  /// сервере залечивалась сама за семь дней, а не никогда.
  static const _freshness = Duration(days: 7);

  static Future<void> onLogin() =>
      ensureRegistered(trigger: PushSyncTrigger.login, force: true);

  static Future<void> onTokenRefresh(String token) =>
      ensureRegistered(trigger: PushSyncTrigger.refresh, force: true);

  static Future<void> onAppResume() =>
      ensureRegistered(trigger: PushSyncTrigger.resume);

  static Future<void> ensureRegistered({
    required PushSyncTrigger trigger,
    bool force = false,
  }) {
    // Гард реентрантности: старт, resume и таймер повтора легко сходятся в
    // три параллельных POST.
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    final future = _run(trigger, force);
    _inFlight = future;
    return future.whenComplete(() => _inFlight = null);
  }

  static Future<void> _run(PushSyncTrigger trigger, bool force) async {
    try {
      // На iOS `getToken()` бросает `apns-token-not-set`, пока APNs-токен не
      // готов. Раньше это исключение глотали без повтора — и токен не
      // появлялся уже никогда.
      if (Platform.isIOS) {
        final apns = await FirebaseMessaging.instance.getAPNSToken();
        if (apns == null) {
          pushLog.warn('APNs token not ready', 'trigger=${trigger.name}');
          _scheduleRetry(trigger);
          return;
        }
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        pushLog.warn('FCM token is null', 'trigger=${trigger.name}');
        _scheduleRetry(trigger);
        return;
      }

      if (await getAuthToken() == null) {
        // Ключевое отличие от старого поведения: токен не выбрасываем, а
        // сохраняем — после логина он уйдёт на сервер.
        await _store.setPendingToken(token);
        pushLog.warn('token minted while unauthenticated — queued');
        return;
      }

      if (!force && await _canSkip(token)) {
        pushLog.info('skip registration (unchanged & fresh)');
        await _store.setPendingToken(null);
        return;
      }

      final result = await _repository.register(token);
      if (result.ok) {
        // Порядок важен: «отправлено» пишем только после ответа сервера.
        await _store.setSent(token, result.statusCode ?? 200);
        await _store.setPendingToken(null);
        _cancelRetry();
        pushLog.info('token registered', 'status=${result.statusCode}');
        return;
      }

      await _store.setError(result.statusCode, result.body);
      pushLog.error(
        'token registration failed',
        'status=${result.statusCode}, body=${result.body}',
      );
      _scheduleRetry(trigger);
    } catch (e, st) {
      pushLog.error('ensureRegistered exception', e.toString(), e, st);
      _scheduleRetry(trigger);
    }
  }

  static Future<bool> _canSkip(String token) async {
    if (await _store.lastSentToken() != token) return false;
    final status = await _store.lastStatus();
    if (status == null || status < 200 || status >= 300) return false;
    final sentAt = await _store.lastSentAt();
    if (sentAt == null) return false;
    return DateTime.now().difference(sentAt) < _freshness;
  }

  static void _scheduleRetry(PushSyncTrigger trigger) {
    if (_retryAttempt >= _retryDelays.length) return;
    final delay = _retryDelays[_retryAttempt];
    _retryAttempt++;
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      ensureRegistered(trigger: trigger);
    });
    pushLog.info('retry scheduled', 'in ${delay.inSeconds}s');
  }

  static void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryAttempt = 0;
  }


  static Future<void> unregisterOnLogout() async {
    try {
      final token = await _store.lastSentToken();
      if (token != null) {
        await _repository.unregister(token);
      }
    } catch (e) {
      pushLog.warn('unregisterOnLogout failed', e.toString());
    } finally {
      // Чистим в любом случае — следующий вход обязан отправить токен заново.
      await _store.clearLastSent();
      await _store.setPendingToken(null);
      _cancelRetry();
    }

    try {
      await FirebaseMessaging.instance.deleteToken();
      pushLog.info('fcm token deleted on logout');
    } catch (e) {
      pushLog.warn('deleteToken failed', e.toString());
    }
  }


  static Future<Map<String, String>> diagnostics() async {
    String? fcm;
    String? apns;
    String? tokenError;
    try {
      if (Platform.isIOS) apns = await FirebaseMessaging.instance.getAPNSToken();
      fcm = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      tokenError = e.toString();
    }
    final settings =
        await FirebaseMessaging.instance.getNotificationSettings();
    return {
      'FCM token': fcm ?? '—',
      if (Platform.isIOS) 'APNs token': apns == null ? 'отсутствует' : 'есть',
      if (tokenError != null) 'Ошибка получения токена': tokenError,
      'Разрешение': settings.authorizationStatus.name,
      'Авторизован': (await getAuthToken()) != null ? 'да' : 'нет',
      'Последний POST': '${await _store.lastStatus() ?? '—'}',
      'Когда отправлен': '${await _store.lastSentAt() ?? '—'}',
      'Последняя ошибка': await _store.lastError() ?? '—',
      'Отложенный токен': (await _store.pendingToken()) != null ? 'есть' : '—',
      'Endpoint': PushTokenRepository.path,
    };
  }
}
