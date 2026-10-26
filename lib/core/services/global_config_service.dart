import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../network/app_dio.dart';
import '../urls.dart';
import 'app_logger.dart';

/// Публичный конфиг бэка (`GET /globalConfig`).
///
/// Ручка отдаёт настройки магазина целиком (цены, лимиты, таймер), здесь
/// разобраны только ссылки на юридические документы — остальные поля
/// добавляются по мере надобности, лишние ключи в ответе игнорируются.
class GlobalConfig {
  const GlobalConfig({this.ofertaUrl, this.privacyPolicyUrl});

  /// `ofertaUrl` — договор оферты.
  final String? ofertaUrl;

  /// `privacyPolicyUrl` — политика конфиденциальности.
  final String? privacyPolicyUrl;

  /// Ссылка под «пользовательское соглашение».
  ///
  /// Подстраховка одним документом на оба поля: в конфиге исторически
  /// заполнено только одно из них (сейчас — `ofertaUrl`), и без фолбэка
  /// вторая ссылка молча не открывалась бы.
  String? get offerDocUrl => ofertaUrl ?? privacyPolicyUrl;

  /// Ссылка под «политику конфиденциальности». См. [offerDocUrl].
  String? get privacyDocUrl => privacyPolicyUrl ?? ofertaUrl;

  factory GlobalConfig.fromJson(Map<String, dynamic> json) => GlobalConfig(
    ofertaUrl: _resolveDocUrl(json['ofertaUrl']),
    privacyPolicyUrl: _resolveDocUrl(json['privacyPolicyUrl']),
  );

  /// Бэк кладёт в эти поля имя объекта в MinIO
  /// (`1741957912979-privacy.policyiris.pdf`), а не готовый адрес — как и для
  /// картинок, его надо склеить с [imgUrl]. Абсолютную ссылку, если она
  /// когда-нибудь придёт, оставляем как есть.
  static String? _resolveDocUrl(Object? raw) {
    if (raw is! String) return null;
    final value = raw.trim();
    if (value.isEmpty) return null;
    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) return value;
    return '$imgUrl$value';
  }
}

/// Загрузка и кэш [GlobalConfig].
///
/// Конфиг меняется редко, поэтому первый успешный ответ живёт до перезапуска
/// приложения. Параллельные вызовы разделяют один запрос — экран авторизации
/// дёргает загрузку и на открытии, и на нажатии по ссылке.
class GlobalConfigService {
  GlobalConfigService._();

  static GlobalConfig? _cached;
  static Future<GlobalConfig?>? _inflight;

  /// Последний удачный ответ, если он уже есть. Без сети.
  static GlobalConfig? get cached => _cached;

  static Future<GlobalConfig?> load({bool forceRefresh = false}) {
    if (!forceRefresh && _cached != null) return Future.value(_cached);
    return _inflight ??= _fetch().whenComplete(() => _inflight = null);
  }

  static Future<GlobalConfig?> _fetch() async {
    try {
      // optionalAuthDio, а не appDio: ручка публичная, а экран авторизации
      // открыт как раз без токена — appDio отклонил бы запрос локально.
      final response = await optionalAuthDio.get<dynamic>(
        '${mainUrl}globalConfig',
      );
      final data = response.data;
      if (data is! Map) {
        netLog.warn('globalConfig: неожиданный формат', '${data.runtimeType}');
        return null;
      }
      final config = GlobalConfig.fromJson(
        data.map((key, value) => MapEntry('$key', value)),
      );
      _cached = config;
      return config;
    } on DioException catch (e) {
      netLog.warn('globalConfig fetch failed', '${e.message}');
      return null;
    } catch (e, st) {
      netLog.error('globalConfig parse failed', null, e, st);
      return null;
    }
  }
}

/// Открывает документ во внешнем приложении (браузер / просмотрщик PDF).
///
/// Внутренний WebView здесь не годится: MinIO отдаёт PDF с
/// `binary/octet-stream`, и на Android такой ответ в WebView превращается в
/// пустой экран вместо документа.
///
/// Возвращает `false`, если ссылки нет или её некому открыть — вызывающий код
/// показывает ошибку, а не гасит нажатие молча.
Future<bool> openDocumentUrl(String? url) async {
  if (url == null || url.trim().isEmpty) return false;
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    netLog.warn('document launch failed', '$uri · $e');
    return false;
  }
}
