import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kAuthTokenKey = 'auth_token';
const _kRefreshTokenKey = 'refresh_token';
const _secureStorage = FlutterSecureStorage();

Future<String?> getAuthToken() async {
  return await _secureStorage.read(key: _kAuthTokenKey);
}

Future<void> setAuthToken(String token) async {
  await _secureStorage.write(key: _kAuthTokenKey, value: token);
}

Future<void> removeAuthToken() async {
  await _secureStorage.delete(key: _kAuthTokenKey);
}

/// Вторая половина пары: refresh-токен из `POST /auth/otp/confirm`.
///
/// Живёт 90 дней со скользящим сроком — каждый успешный `POST /auth/refresh`
/// отодвигает истечение. Ротации у бэкенда нет: в ответе приходит тот же самый
/// токен, поэтому после рефреша перезаписывать его не нужно.
Future<String?> getRefreshToken() async {
  return await _secureStorage.read(key: _kRefreshTokenKey);
}

Future<void> setRefreshToken(String token) async {
  await _secureStorage.write(key: _kRefreshTokenKey, value: token);
}

Future<void> removeRefreshToken() async {
  await _secureStorage.delete(key: _kRefreshTokenKey);
}

/// Полный разлогин — стирает обе половины пары.
///
/// Везде, где раньше хватало одного [removeAuthToken], теперь нужен именно он:
/// оставленный refresh-токен позволил бы восстановить сессию.
Future<void> clearTokens() async {
  await removeAuthToken();
  await removeRefreshToken();
}
