import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Локальное хранилище PIN-кода: солёный SHA-256 хеш в secure storage.
/// Проверка PIN выполняется на устройстве (у бэкенда нет PIN-эндпоинта).
const _kPinHashKey = 'pin_hash';
const _kPinSaltKey = 'pin_salt';
const _secureStorage = FlutterSecureStorage();

String _hash(String pin, String salt) =>
    sha256.convert(utf8.encode('$salt:$pin')).toString();

String _generateSalt() {
  final rnd = Random.secure();
  final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
  return base64Url.encode(bytes);
}

/// Сохраняет новый PIN (генерирует свежую соль).
Future<void> setPin(String pin) async {
  final salt = _generateSalt();
  await _secureStorage.write(key: _kPinSaltKey, value: salt);
  await _secureStorage.write(key: _kPinHashKey, value: _hash(pin, salt));
}

/// Установлен ли PIN.
Future<bool> hasPin() async {
  final hash = await _secureStorage.read(key: _kPinHashKey);
  return hash != null && hash.isNotEmpty;
}

/// Совпадает ли [pin] с сохранённым.
Future<bool> verifyPin(String pin) async {
  final salt = await _secureStorage.read(key: _kPinSaltKey);
  final hash = await _secureStorage.read(key: _kPinHashKey);
  if (salt == null || hash == null) return false;
  return _hash(pin, salt) == hash;
}

/// Удаляет PIN (например, при выходе из аккаунта).
Future<void> removePin() async {
  await _secureStorage.delete(key: _kPinHashKey);
  await _secureStorage.delete(key: _kPinSaltKey);
}
