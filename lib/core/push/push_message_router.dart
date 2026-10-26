import 'dart:async';

import 'package:url_launcher/url_launcher.dart';

import '../routing/app_routing.dart';
import '../services/app_logger.dart';
import '../urls.dart';
import '../../features/live/presentation/widgets/live_shopping_scope.dart';

/// Куда вести по тапу на уведомление.
///
/// [resolveRoute] намеренно чистая — её можно проверить тестом, и это важно:
/// кривой payload из админки не должен ронять приложение (GoRouter бросает на
/// неизвестном пути).
class PushMessageRouter {
  PushMessageRouter._();

  /// Маршруты, на которые разрешено уводить из пуша.
  static const _knownPrefixes = <String>[
    '/product/',
    '/collection/',
    '/seller/',
    '/raffle/',
    '/notification/',
    '/live/',
  ];

  static const _knownExact = <String>{
    '/main',
    '/catalog',
    '/cart',
    '/profile',
    '/orders',
    '/favorites',
    '/tickets',
    '/prizes',
    '/plus',
    '/streams',
    '/notification',
  };

  /// Голый `/live` больше не маршрут — эфир открывается только по id. Но в
  /// очереди уже могут висеть отправленные админкой пуши со старой ссылкой,
  /// поэтому уводим их на вкладку «Эфиры», а не в «неизвестный маршрут».
  static const _legacyAliases = <String, String>{'/live': '/streams'};

  /// Маршруты, которые из пуша ведут не в приложение, а на внешний сайт.
  ///
  /// Сами маршруты остаются в [_knownExact]: [resolveRoute] по-прежнему отдаёт
  /// `/tickets`, подмена на ссылку происходит только в момент перехода.
  /// «Мои билеты» в профиле тоже открывают sz.kz — пуши ведут туда же.
  static const _externalRoutes = <String, String>{
    '/tickets': sattyJuldyzLoginUrl,
  };

  /// Внешняя ссылка для [route] или `null`, если это обычный маршрут
  /// приложения. Чистая, как и [resolveRoute], — проверяется тестом.
  static String? externalUrlFor(String route) => _externalRoutes[route];

  static String resolveRoute(Map<String, dynamic> data) {
    final candidate = _firstNonEmpty(data, const [
      'deeplink',
      'deepLink',
      'buttonLink',
      'link',
      'route',
    ]);
    final normalized = _legacyAliases[_normalize(candidate)] ??
        _normalize(candidate);
    if (normalized != null && _isKnown(normalized)) return normalized;

    // Фолбэк по типу: категории уведомлений открываются как /notification/<тип>.
    final type = data['type'];
    if (type is String && type.trim().isNotEmpty) {
      final byType = '/notification/${type.trim()}';
      if (_isKnown(byType)) return byType;
    }
    return '/notification';
  }

  /// Приводит `baimarket://product/42`, `https://…/product/42` и `/product/42`
  /// к общему виду `/product/42`.
  static String? _normalize(String? raw) {
    if (raw == null) return null;
    var value = raw.trim();
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) {
      final path = uri.path.isEmpty ? '' : uri.path;
      // У кастомной схемы `baimarket://product/42` хост это «product».
      final host = uri.host;
      value = host.isNotEmpty && uri.scheme != 'http' && uri.scheme != 'https'
          ? '/$host$path'
          : path;
    }
    if (value.isEmpty) return null;
    if (!value.startsWith('/')) value = '/$value';
    return value;
  }

  static bool _isKnown(String route) {
    if (_knownExact.contains(route)) return true;
    for (final prefix in _knownPrefixes) {
      if (route.startsWith(prefix) && route.length > prefix.length) return true;
    }
    return false;
  }

  static String? _firstNonEmpty(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) return value;
    }
    return null;
  }

  /// Маршрут, который не удалось открыть, потому что роутер ещё не готов
  /// (холодный старт по тапу на уведомление).
  static String? _pending;

  static Future<void> handleTap(Map<String, dynamic> data) async {
    final route = resolveRoute(data);
    pushLog.nav('notification tap → $route');
    if (!_tryGo(route)) _pending = route;
  }

  /// Вызывается после первого кадра — тогда роутер уже примонтирован.
  static void drainPending() {
    final route = _pending;
    if (route == null) return;
    if (_tryGo(route)) _pending = null;
  }

  static bool _tryGo(String route) {
    // Пока идёт эфир или открыт просмотрщик сториз, push оборвал бы
    // WebRTC-сессию. Уведомление всё равно лежит в списке — откроют оттуда.
    if (LiveShoppingController.current != null) {
      pushLog.nav('навигация пропущена: открыт полноэкранный медиа-экран');
      return true;
    }
    final external = externalUrlFor(route);
    if (external != null) {
      unawaited(_openExternal(external));
      return true;
    }
    try {
      router.push(route); // live-nav-ok: выше стоит проверка на медиа-экран
      return true;
    } catch (e) {
      pushLog.warn('router not ready', e.toString());
      return false;
    }
  }

  static Future<void> _openExternal(String url) async {
    try {
      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok) pushLog.warn('external link not opened', url);
    } catch (e) {
      pushLog.warn('external link failed', '$url: $e');
    }
  }
}
