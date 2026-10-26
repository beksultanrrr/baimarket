import 'dart:convert';
import 'dart:io';

import 'package:bai_market/features/app_update/data/datasources/app_update_services.dart';
import 'package:bai_market/features/app_update/data/models/app_update_info.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Сквозная проверка датасорса против настоящего HTTP-сервера: реальный Dio,
/// реальные заголовки, реальный разбор тела. Юнит-тесты моделей этого не
/// ловят — а ломается обычно именно стык.
void main() {
  late HttpServer server;

  /// Что отдаёт «Hosting» в этом тесте.
  late int status;
  late String body;
  late ContentType contentType;

  setUp(() async {
    status = 200;
    body = '{}';
    contentType = ContentType.json;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response
        ..statusCode = status
        ..headers.contentType = contentType
        ..write(body);
      await request.response.close();
    });
  });

  tearDown(() => server.close(force: true));

  /// Перенаправляет запросы датасорса на локальный сервер, не трогая путь и
  /// query — то есть проверяется в том числе cache-buster `?ts=`.
  Dio dioToLocalServer() {
    final dio = Dio(BaseOptions(validateStatus: (_) => true));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Только схема, хост и порт. Query не переносим: его Dio допишет
          // сам из queryParameters, иначе `ts` продублируется.
          final target = Uri(
            scheme: 'http',
            host: server.address.host,
            port: server.port,
            path: options.uri.path,
          );
          handler.next(options.copyWith(path: target.toString()));
        },
      ),
    );
    return dio;
  }

  AppUpdateServices services({String installed = '1.0.7'}) => AppUpdateServices(
    dio: dioToLocalServer(),
    packageInfo: PackageInfo(
      appName: 'Bai Market',
      packageName: 'com.bmarket.baimarket',
      version: installed,
      buildNumber: '23',
    ),
  );

  String manifest(String latest, {String? min, String? storeUrl}) => jsonEncode({
    'android': {
      'latestVersion': latest,
      if (min != null) 'minSupportedVersion': min,
      if (storeUrl != null) 'storeUrl': storeUrl,
      'releaseNotes': {'ru': 'Починили корзину'},
    },
    'ios': {'latestVersion': latest},
  });

  test('MAJOR в манифесте → обязательное обновление', () async {
    body = manifest('2.0.0');
    final info = await services().checkForUpdate();
    expect(info, isNotNull);
    expect(info!.severity, AppUpdateSeverity.forced);
    expect(info.isForced, isTrue);
    expect(info.latestVersion.raw, '2.0.0');
    expect(info.notesFor('ru'), 'Починили корзину');
  });

  test('MINOR → рекомендованное', () async {
    body = manifest('1.1.0');
    final info = await services().checkForUpdate();
    expect(info!.severity, AppUpdateSeverity.recommended);
  });

  test('PATCH → ничего', () async {
    body = manifest('1.0.8');
    final info = await services().checkForUpdate();
    expect(info!.severity, AppUpdateSeverity.none);
  });

  test('minSupportedVersion блокирует и на PATCH', () async {
    body = manifest('1.0.8', min: '1.0.8');
    final info = await services().checkForUpdate();
    expect(info!.severity, AppUpdateSeverity.forced);
  });

  test('storeUrl из манифеста доезжает до UI', () async {
    body = manifest('2.0.0', storeUrl: 'https://example.com/track/beta');
    final info = await services().checkForUpdate();
    expect(info!.storeUrl, 'https://example.com/track/beta');
  });

  test('без storeUrl берётся ссылка по умолчанию', () async {
    body = manifest('2.0.0');
    final info = await services().checkForUpdate();
    // Тест идёт на macOS, поэтому платформенная ветка — андроидная. Главное,
    // что ссылка собрана из playListingId, а не из applicationId сборки.
    expect(info!.storeUrl, contains('id=com.baimarket.baimarket'));
  });

  test('JSON под чужим content-type всё равно разбирается', () async {
    // Ровно случай App Store Lookup: тело — JSON, заголовок — text/javascript,
    // и Dio оставляет его строкой.
    // charset обязателен: dart:io кодирует тело ответа по нему, и без utf-8
    // кириллица в releaseNotes уронила бы сам тестовый сервер.
    contentType = ContentType('text', 'javascript', charset: 'utf-8');
    body = manifest('2.0.0');
    final info = await services().checkForUpdate();
    expect(info!.severity, AppUpdateSeverity.forced);
  });

  test('незадеплоенный манифест (HTML под 200) не показывает диалог', () async {
    // Из-за rewrites `** → /index.html` Hosting отдаёт на этот путь страницу с
    // кодом 200. Приложение обязано понять, что источника нет, а не упасть.
    contentType = ContentType.html;
    body = '<!DOCTYPE html><html><body>Bai Market</body></html>';
    expect(await services().checkForUpdate(), isNull);
  });

  test('404 не показывает диалог', () async {
    status = 404;
    body = 'Not Found';
    expect(await services().checkForUpdate(), isNull);
  });

  test('манифест без latestVersion не показывает диалог', () async {
    body = jsonEncode({
      'android': {'minSupportedVersion': '1.0.0'},
    });
    expect(await services().checkForUpdate(), isNull);
  });

  test('плоский манифест без платформенных блоков читается', () async {
    body = jsonEncode({'latestVersion': '2.0.0'});
    final info = await services().checkForUpdate();
    expect(info!.severity, AppUpdateSeverity.forced);
  });

  test('сервер недоступен → диалога нет, приложение работает', () async {
    await server.close(force: true);
    expect(await services().checkForUpdate(), isNull);
  });
}
