import 'dart:convert';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/services/app_logger.dart';
import '../../../../core/urls.dart';
import '../../domain/repositories/app_update_repository.dart';
import '../models/app_update_info.dart';
import '../models/app_version.dart';


class AppUpdateServices implements AppUpdateRepository {
  AppUpdateServices({Dio? dio, PackageInfo? packageInfo})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              // Проверка обновления не должна задерживать запуск: не ответили
              // за шесть секунд — считаем, что источника нет.
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 6),
              // 4xx/5xx разбираем сами, без исключений.
              validateStatus: (_) => true,
            ),
          ) {
    _packageInfo = packageInfo;
  }

  final Dio _dio;


  PackageInfo? _packageInfo;

  @override
  Future<AppUpdateInfo?> checkForUpdate() async {
    final current = await _currentVersion();
    if (current == null) {
      updateLog.warn('current version unreadable — проверка пропущена');
      return null;
    }

    // Демо-режим перехватывает проверку до сети — иначе он бы зависел ровно от
    // того источника, вместо которого его и включают.
    final demo = _demoUpdate(current);
    if (demo != null) return demo;

    final remote = await _fetchManifest() ?? await _fetchFromStore();
    if (remote == null) {
      updateLog.warn('no version source available', 'current=$current');
      return null;
    }

    final severity = AppUpdateInfo.severityFor(
      current: current,
      latest: remote.latest,
      minSupported: remote.minSupported,
      allowForce: remote.allowForce,
    );
    updateLog.info(
      'severity=${severity.name}',
      'current=$current latest=${remote.latest} '
          'min=${remote.minSupported} force=${remote.allowForce}',
    );

    return AppUpdateInfo(
      severity: severity,
      currentVersion: current,
      latestVersion: remote.latest,
      storeUrl: remote.storeUrl ?? _defaultStoreUrl,
      releaseNotes: remote.releaseNotes,
    );
  }

  /// Подмена «установленной» версии для проверки диалога:
  /// `flutter run --dart-define=UPDATE_FAKE_VERSION=0.9.0`
  ///
  /// Занизив версию, вы получаете расхождение с манифестом нужного разряда и
  /// видите тот диалог, который хотите: `0.9.0` против `1.0.7` — обязательное,
  /// `1.0.7` против манифеста с MINOR выше — рекомендованное.
  static const _fakeVersion = String.fromEnvironment('UPDATE_FAKE_VERSION');

  /// Прямой показ нужной карточки, без манифеста и без сети:
  ///
  /// ```
  /// flutter run --dart-define=UPDATE_DEMO=forced
  /// flutter run --dart-define=UPDATE_DEMO=recommended
  /// ```
  ///
  /// Чем отличается от [_fakeVersion]: тот подменяет только установленную
  /// версию и всё равно требует живого источника. А источника сейчас нет —
  /// манифест на Hosting не выкачен, у Android запасного варианта не
  /// предусмотрено вовсе, — поэтому одной подмены версии не хватает.
  static const _demoSeverity = String.fromEnvironment('UPDATE_DEMO');

  /// Синтетический ответ для [_demoSeverity].
  ///
  /// В релизе выключен всегда, по той же причине, что и подмена версии:
  /// `--dart-define`, забытый в конфигурации CI, не должен уметь запереть прод
  /// в диалоге, который не закрывается.
  AppUpdateInfo? _demoUpdate(AppVersion current) {
    if (_demoSeverity.isEmpty || kReleaseMode) return null;
    final severity = switch (_demoSeverity.trim().toLowerCase()) {
      'forced' || 'force' || 'required' => AppUpdateSeverity.forced,
      'recommended' || 'soft' || 'optional' => AppUpdateSeverity.recommended,
      'none' || 'off' => AppUpdateSeverity.none,
      _ => null,
    };
    if (severity == null) {
      updateLog.warn('UPDATE_DEMO не распознан — проверка идёт как обычно',
          _demoSeverity);
      return null;
    }

    // Версию «из магазина» выводим из установленной, а не берём константой:
    // разряд должен разойтись ровно тот, который отвечает за выбранную
    // строгость, иначе в карточке будет написано одно, а показано другое.
    final latest = switch (severity) {
      AppUpdateSeverity.forced => AppVersion(current.major + 1, 0, 0,
          raw: '${current.major + 1}.0.0'),
      AppUpdateSeverity.recommended => AppVersion(
          current.major, current.minor + 1, 0,
          raw: '${current.major}.${current.minor + 1}.0'),
      AppUpdateSeverity.none => current,
    };

    updateLog.warn('ДЕМО-РЕЖИМ обновления', '${severity.name} → $latest');
    return AppUpdateInfo(
      severity: severity,
      currentVersion: current,
      latestVersion: latest,
      storeUrl: _defaultStoreUrl,
    );
  }

  /// Версия установленной сборки: `CFBundleShortVersionString` на iOS,
  /// `versionName` на Android — обе заполняются из `version:` в pubspec.
  Future<AppVersion?> _currentVersion() async {
    // В релизе игнорируется всегда: забытый в CI `--dart-define` не должен
    // уметь запереть прод в блокирующем диалоге.
    if (_fakeVersion.isNotEmpty && !kReleaseMode) {
      updateLog.warn('ПОДМЕНА версии для отладки', _fakeVersion);
      return AppVersion.tryParse(_fakeVersion);
    }
    try {
      final info = _packageInfo ??= await PackageInfo.fromPlatform();
      return AppVersion.tryParse(info.version);
    } catch (e, st) {
      updateLog.error('PackageInfo failed', null, e, st);
      return null;
    }
  }

  String get _platformKey => Platform.isIOS ? 'ios' : 'android';

  String get _defaultStoreUrl => Platform.isIOS ? appStoreUrl : playStoreUrl;

  /// Манифест `app-version.json` с Firebase Hosting.
  Future<RemoteAppVersion?> _fetchManifest() async {
    try {
      final response = await _dio.get<dynamic>(
        appVersionManifestUrl,
        queryParameters: {
          // Обход кэша CDN и системного HTTP-кэша: манифест обязан
          // отрабатывать сразу после деплоя, иначе обязательное обновление
          // доедет до пользователей с задержкой в час.
          'ts': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        options: Options(headers: const {'Cache-Control': 'no-cache'}),
      );
      if (response.statusCode != 200) {
        updateLog.warn('manifest ${response.statusCode}');
        return null;
      }
      final json = _asMap(response.data);
      if (json == null) return null;
      final block = json[_platformKey] ?? json;
      final parsed = RemoteAppVersion.tryParse(block);
      if (parsed == null) {
        updateLog.warn('manifest без latestVersion', _platformKey);
      }
      return parsed;
    } catch (e) {
      updateLog.warn('manifest fetch failed', '$e');
      return null;
    }
  }

  /// Запасной источник для iOS. Для Android аналога нет: у Google Play нет
  /// публичного API, а парсинг HTML ломается при каждом редизайне страницы —
  /// молча и в проде.
  ///
  /// Результат помечен `allowForce: false` — см. комментарий у поля.
  Future<RemoteAppVersion?> _fetchFromStore() async {
    if (!Platform.isIOS) return null;
    try {
      final response = await _dio.get<dynamic>(appStoreLookupUrl);
      if (response.statusCode != 200) return null;
      // Lookup отдаёт `text/javascript`, поэтому Dio оставляет тело строкой —
      // без ручного decode здесь был бы null на ровном месте.
      final json = _asMap(response.data);
      final results = json?['results'];
      if (results is! List || results.isEmpty) return null;
      final first = _asMap(results.first);
      final latest = AppVersion.tryParse(first?['version'] as String?);
      if (latest == null) return null;
      updateLog.info('fallback: App Store version $latest');
      return RemoteAppVersion(
        latest: latest,
        storeUrl: first?['trackViewUrl'] as String?,
        allowForce: false,
      );
    } catch (e) {
      updateLog.warn('App Store lookup failed', '$e');
      return null;
    }
  }

  static Map<String, dynamic>? _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.map((k, v) => MapEntry('$k', v));
    if (data is String && data.trim().isNotEmpty) {
      try {
        return _asMap(jsonDecode(data));
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
