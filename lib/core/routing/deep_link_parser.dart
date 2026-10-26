import '../urls.dart';

/// Приводит входящую ссылку к пути, который понимает GoRouter.
///
/// Встроенный диплинкинг Flutter отдаёт роутеру **весь URI** строкой
/// (`Uri.getData().toString()` на Android, `url.absoluteString` на iOS), а
/// go_router матчит маршруты только по `uri.path`. Для https всё сходится само:
/// у `https://host/product/42` путь и есть `/product/42`.
///
/// Ломается кастомная схема: `baimarket://product/42` — это host `product` и
/// путь `/42`. Такого маршрута нет, и пользователь получил бы экран ошибки
/// вместо товара. Здесь host возвращается в начало пути.
///
/// Возвращает `null`, если из ссылки не удалось достать ни одного сегмента.
String? normalizeDeepLink(Uri uri) {
  final segments = <String>[];

  // У кастомной схемы authority — это первый сегмент маршрута. У http(s) это
  // настоящий домен, и трогать его нельзя.
  final isCustomScheme = uri.scheme.isNotEmpty &&
      uri.scheme != 'http' &&
      uri.scheme != 'https';
  if (isCustomScheme && uri.host.isNotEmpty) {
    segments.add(uri.host);
  }
  segments.addAll(uri.pathSegments.where((s) => s.isNotEmpty));

  if (segments.isEmpty) return null;

  final path = '/${segments.join('/')}';
  return uri.hasQuery ? '$path?${uri.query}' : path;
}

/// Ссылка вида `baimarket:///product/42` для страницы-заглушки и тестов.
///
/// Три слэша не опечатка: пустой authority оставляет путь целиком в `path`, и
/// [normalizeDeepLink] такой ссылке уже не нужен.
String appSchemeLink(String path) =>
    '$appUrlScheme://${path.startsWith('/') ? path : '/$path'}';
