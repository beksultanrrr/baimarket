import 'package:shared_preferences/shared_preferences.dart';

/// Состояние регистрации пуш-токена на сервере.
///
/// Хранится в `SharedPreferences`, потому что переживать перезапуск обязано:
/// именно отсутствие такой памяти приводило к тому, что токен, полученный до
/// логина, просто терялся.
class PushRegistrationStore {
  static const _kLastSentToken = 'push_last_sent_token';
  static const _kLastSentAt = 'push_last_sent_at';
  static const _kLastStatus = 'push_last_status';
  static const _kLastError = 'push_last_error';
  static const _kPendingToken = 'push_pending_token';
  static const _kPermissionAsked = 'push_permission_asked';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<String?> lastSentToken() async =>
      (await _prefs).getString(_kLastSentToken);

  Future<DateTime?> lastSentAt() async {
    final ms = (await _prefs).getInt(_kLastSentAt);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<int?> lastStatus() async => (await _prefs).getInt(_kLastStatus);

  Future<String?> lastError() async => (await _prefs).getString(_kLastError);

  /// Токен, полученный когда пользователь ещё не авторизован. Отправится
  /// сразу после логина.
  Future<String?> pendingToken() async =>
      (await _prefs).getString(_kPendingToken);

  Future<void> setPendingToken(String? token) async {
    final prefs = await _prefs;
    if (token == null) {
      await prefs.remove(_kPendingToken);
    } else {
      await prefs.setString(_kPendingToken, token);
    }
  }

  /// Вызывать **только после** успешного ответа сервера. Запись до ответа
  /// навсегда выключила бы повторные попытки — это было бы хуже текущего
  /// поведения, а не лучше.
  Future<void> setSent(String token, int status) async {
    final prefs = await _prefs;
    await prefs.setString(_kLastSentToken, token);
    await prefs.setInt(_kLastSentAt, DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt(_kLastStatus, status);
    await prefs.remove(_kLastError);
  }

  Future<void> setError(int? status, String? body) async {
    final prefs = await _prefs;
    if (status != null) await prefs.setInt(_kLastStatus, status);
    await prefs.setString(_kLastError, body ?? 'unknown');
  }

  /// После логаута — чтобы следующий вход обязательно отправил токен заново.
  Future<void> clearLastSent() async {
    final prefs = await _prefs;
    await prefs.remove(_kLastSentToken);
    await prefs.remove(_kLastSentAt);
  }

  Future<bool> permissionAsked() async =>
      (await _prefs).getBool(_kPermissionAsked) ?? false;

  Future<void> setPermissionAsked() async {
    await (await _prefs).setBool(_kPermissionAsked, true);
  }
}
