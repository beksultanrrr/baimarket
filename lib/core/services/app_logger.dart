import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

/// Универсальный логер. Все строки идут через `dart:developer.log()` —
/// видны во Flutter DevTools (Logging tab, фильтр по `name`). В debug-сборке
/// дублируется в `debugPrint`, чтобы было видно в обычном `flutter run` логе.
///
/// Каждый домен заводит свой инстанс с уникальным тегом — облегчает grep:
/// `flutter run | grep AUTH` / `... | grep CART` etc.
class AppLogger {
  const AppLogger(this.tag);

  final String tag;

  // Универсальные категории. Для большинства событий хватает `info` + `step`,
  // отдельные методы (`api`, `nav`, `state`, `event`, `emit`) нужны чтобы
  // быстро отличать тип события глазом.
  void info(String message, [Object? data]) => _log('info', message, data);
  void warn(String message, [Object? data]) => _log('warn', message, data);
  void step(String message, [Object? data]) => _log('step', message, data);
  void api(String message, [Object? data]) => _log('api', message, data);
  void state(String message, [Object? data]) => _log('state', message, data);
  void nav(String message, [Object? data]) => _log('nav', message, data);
  void event(String message, [Object? data]) => _log('event', message, data);
  void emit(String message, [Object? data]) => _log('emit', message, data);
  void poll(String message, [Object? data]) => _log('poll', message, data);
  void connect(String message, [Object? data]) =>
      _log('connect', message, data);

  void error(String message, [Object? data, Object? err, StackTrace? st]) {
    final payload = _format('error', message, data);
    dev.log(payload, name: tag, error: err, stackTrace: st, level: 1000);
    if (kDebugMode) debugPrint('[$tag] $payload');
  }

  void _log(String category, String message, Object? data) {
    final payload = _format(category, message, data);
    dev.log(payload, name: tag);
    if (kDebugMode) debugPrint('[$tag] $payload');
  }

  String _format(String category, String message, Object? data) {
    final ts = _ts();
    final base = '$ts $category :: $message';
    if (data == null) return base;
    return '$base ${_truncate(data.toString(), 600)}';
  }

  String _ts() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    String three(int v) => v.toString().padLeft(3, '0');
    return '${two(now.hour)}:${two(now.minute)}:${two(now.second)}.'
        '${three(now.millisecond)}';
  }

  String _truncate(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}…(+${s.length - max})';
}

/// Тегированные инстансы по доменам. Использовать как `authLog.step(...)`.
const authLog = AppLogger('AUTH');
const cartLog = AppLogger('CART');
const paymentLog = AppLogger('PAYMENT');
const profileLog = AppLogger('PROFILE');
const favLog = AppLogger('FAV');
const routerLog = AppLogger('ROUTER');
const netLog = AppLogger('NET');
const searchLog = AppLogger('SEARCH');
const sellerLog = AppLogger('SELLER');
const reviewsLog = AppLogger('REVIEWS');
const productLog = AppLogger('PRODUCT');
const pushLog = AppLogger('PUSH');
const storiesLog = AppLogger('STORIES');
const updateLog = AppLogger('UPDATE');
