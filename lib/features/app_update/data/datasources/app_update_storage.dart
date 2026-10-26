import 'package:shared_preferences/shared_preferences.dart';

/// Память об отложенных обновлениях.
///
/// Нужна только для рекомендованных: показывать «вышла новая версия» на каждом
/// запуске — верный способ приучить закрывать диалог не читая, после чего
/// обязательное обновление тоже закроют не глядя. Обязательное не откладывается
/// никогда и сюда не попадает.
const _kSnoozedVersionKey = 'app_update_snoozed_version';
const _kSnoozedAtKey = 'app_update_snoozed_at';

/// Сколько молчим после «Позже» по одной и той же версии.
const Duration kUpdateSnoozeDuration = Duration(hours: 24);

Future<void> snoozeUpdate(String version) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kSnoozedVersionKey, version);
  await prefs.setInt(_kSnoozedAtKey, DateTime.now().millisecondsSinceEpoch);
}

/// Отложена ли ИМЕННО эта версия и не истёк ли срок.
///
/// Сравнение по версии обязательно: после выхода следующей сборки прошлое
/// «Позже» силы не имеет.
Future<bool> isUpdateSnoozed(String version) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getString(_kSnoozedVersionKey) != version) return false;
  final at = prefs.getInt(_kSnoozedAtKey);
  if (at == null) return false;
  final elapsed = DateTime.now().millisecondsSinceEpoch - at;
  // Отрицательное значение — пользователь перевёл часы назад. Считаем, что
  // отсрочка истекла: лучше лишний раз показать, чем замолчать навсегда.
  if (elapsed < 0) return false;
  return elapsed < kUpdateSnoozeDuration.inMilliseconds;
}
