/// Разобранная версия приложения вида `1.0.7`.
///
/// Отдельный тип, а не сравнение строк: `"1.0.10" < "1.0.9"` лексикографически,
/// и на этом ломается любая наивная проверка обновлений.
class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.major, this.minor, this.patch, {this.raw = ''});

  final int major;
  final int minor;
  final int patch;

  /// Исходная строка — показываем её в диалоге как есть (`1.0.7`), чтобы
  /// пользователь видел то же, что написано в магазине.
  final String raw;

  static final RegExp _digits = RegExp(r'\d+');

  /// Терпимый парсер: на вход прилетают строки из трёх независимых источников
  /// (pubspec-бандл, наш манифест, iTunes Lookup), и все три пишут версии
  /// по-разному. Поддерживаются `1.0.7`, `1.0.7+23`, `1.0.7-beta.2`, `v1.0.7`,
  /// `3.0`, `2`. Мусор без единой цифры даёт `null` — вызывающий код в этом
  /// случае обязан НЕ показывать диалог, а не подставлять нули.
  static AppVersion? tryParse(String? source) {
    if (source == null) return null;
    final trimmed = source.trim();
    if (trimmed.isEmpty) return null;
    // Build-номер (`+23`) и pre-release (`-beta.2`) отрезаем: на порядок
    // сравнения они не влияют, а цифрами в них можно испортить patch.
    final core = trimmed.split('+').first.split('-').first;
    final parts = _digits
        .allMatches(core)
        .map((m) => int.tryParse(m.group(0)!) ?? 0)
        .toList();
    if (parts.isEmpty) return null;
    int at(int i) => i < parts.length ? parts[i] : 0;
    return AppVersion(at(0), at(1), at(2), raw: trimmed);
  }

  /// Недостающие разряды считаются нулями: `3.0` == `3.0.0`. Так магазинная
  /// «3.0» корректно сравнивается с локальной «1.0.7».
  @override
  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  bool operator >(AppVersion other) => compareTo(other) > 0;
  bool operator <(AppVersion other) => compareTo(other) < 0;
  bool operator >=(AppVersion other) => compareTo(other) >= 0;
  bool operator <=(AppVersion other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) =>
      other is AppVersion &&
      major == other.major &&
      minor == other.minor &&
      patch == other.patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}
