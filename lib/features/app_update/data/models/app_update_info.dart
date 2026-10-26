import 'app_version.dart';

/// Насколько срочно нужно обновиться. Правило разрядов задано продуктом:
/// меняется MAJOR — блокируем, MINOR — предлагаем, PATCH — молчим.
enum AppUpdateSeverity {
  /// Ставить нечего либо разошёлся только PATCH (`1.0.7` → `1.0.8`).
  none,

  /// Разошёлся MINOR (`1.0.7` → `1.1.0`). Диалог закрывается, «Позже» есть.
  recommended,

  /// Разошёлся MAJOR (`1.0.7` → `2.0.0`) либо сборка ниже `minSupportedVersion`.
  /// Диалог не закрывается ничем: ни кнопкой, ни свайпом, ни системным «назад».
  forced,
}

/// Сырые данные о версии из источника (манифест на Hosting либо магазин).
class RemoteAppVersion {
  const RemoteAppVersion({
    required this.latest,
    this.minSupported,
    this.storeUrl,
    this.releaseNotes = const {},
    this.allowForce = true,
  });

  /// Последняя опубликованная версия.
  final AppVersion latest;

  /// Явный пол поддерживаемых версий. Бьёт правило разрядов: хотфикс в PATCH
  /// тоже можно сделать обязательным, не выпуская ради этого мажор.
  final AppVersion? minSupported;

  /// Ссылка на карточку в магазине. `null` — соберём дефолтную из констант.
  final String? storeUrl;

  /// Текст «что нового» по кодам локалей (`ru`, `en`, `kk`).
  final Map<String, String> releaseNotes;

  /// Может ли этот источник приводить к БЛОКИРУЮЩЕМУ диалогу.
  ///
  /// `false` у магазинных фолбэков, и это не перестраховка: версия в App Store
  /// живёт по своей нумерации и обновляется в выдаче с задержкой. Один
  /// расхождение в MAJOR — и эвристика запрёт всех живых пользователей в
  /// экране, который нельзя закрыть. Заблокировать приложение имеет право
  /// только источник, которым команда управляет вручную, — манифест.
  final bool allowForce;

  /// Разбор одного платформенного блока манифеста.
  ///
  /// Парсер намеренно защитный, без `as`: манифест гейтит вход в приложение,
  /// и опечатка в нём не должна ронять проверку исключением. Всё, что не
  /// распозналось, просто отсутствует.
  static RemoteAppVersion? tryParse(Object? json) {
    if (json is! Map) return null;
    final latest = AppVersion.tryParse(_string(json['latestVersion']));
    if (latest == null) return null;
    final url = _string(json['storeUrl']);
    return RemoteAppVersion(
      latest: latest,
      minSupported: AppVersion.tryParse(_string(json['minSupportedVersion'])),
      storeUrl: (url != null && url.isNotEmpty) ? url : null,
      releaseNotes: _notes(json['releaseNotes']),
    );
  }

  static String? _string(Object? v) => v is String ? v : (v == null ? null : '$v');

  static Map<String, String> _notes(Object? v) {
    if (v is String) return {'*': v};
    if (v is! Map) return const {};
    final out = <String, String>{};
    v.forEach((key, value) {
      if (key is String && value is String && value.trim().isNotEmpty) {
        out[key] = value.trim();
      }
    });
    return out;
  }
}

/// Готовое решение для UI: что показать и куда вести.
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.severity,
    required this.currentVersion,
    required this.latestVersion,
    required this.storeUrl,
    this.releaseNotes = const {},
  });

  final AppUpdateSeverity severity;
  final AppVersion currentVersion;
  final AppVersion latestVersion;
  final String storeUrl;
  final Map<String, String> releaseNotes;

  bool get isForced => severity == AppUpdateSeverity.forced;

  /// «Что нового» под текущую локаль, с откатом на русский и на `*`.
  String? notesFor(String localeCode) {
    for (final key in [localeCode, 'ru', 'en', '*']) {
      final text = releaseNotes[key];
      if (text != null && text.trim().isNotEmpty) return text.trim();
    }
    return null;
  }

  /// Единственное место, где живёт правило «MAJOR / MINOR / PATCH».
  ///
  /// Порядок проверок важен:
  /// 1. `minSupported` — явная воля команды, бьёт всё остальное;
  /// 2. версия не выше текущей — выходим, иначе откат сборки в магазине
  ///    показал бы «обновитесь» на более новой версии;
  /// 3. дальше собственно разряды.
  static AppUpdateSeverity severityFor({
    required AppVersion current,
    required AppVersion latest,
    AppVersion? minSupported,
    bool allowForce = true,
  }) {
    if (allowForce && minSupported != null && current < minSupported) {
      return AppUpdateSeverity.forced;
    }
    if (latest <= current) return AppUpdateSeverity.none;
    if (latest.major > current.major) {
      // Источник без права блокировать всё равно должен позвать обновиться —
      // просто мягко.
      return allowForce
          ? AppUpdateSeverity.forced
          : AppUpdateSeverity.recommended;
    }
    if (latest.major == current.major && latest.minor > current.minor) {
      return AppUpdateSeverity.recommended;
    }
    // Разошёлся только PATCH — по требованию продукта не беспокоим вообще.
    return AppUpdateSeverity.none;
  }
}
