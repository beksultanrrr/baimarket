import 'package:json_annotation/json_annotation.dart';

import '../../../../core/urls.dart';

part 'story_model.g.dart';

/// Одна сториз продавца.
///
/// Живёт 24 часа от создания; просроченные бэк из ленты убирает сам, а раз в
/// час крон удаляет их вместе с файлами в MinIO.
@JsonSerializable()
class StoryModel {
  final int id;

  /// Имя файла в MinIO, а не ссылка. Полный путь — `$imgUrl$mediaUrl`.
  final String? mediaUrl;

  /// `IMAGE` или `VIDEO`. Намеренно строка, а не enum: незнакомое значение с
  /// сервера не должно ронять `fromJson` внутри разбора всей ленты.
  final String? mediaType;

  /// Необязательный переход на товар по тапу. `null` — просто картинка.
  final int? modelId;

  /// ISO-строки, как во всех моделях этого репозитория.
  final String? createdAt;
  final String? expiresAt;

  @JsonKey(defaultValue: false)
  final bool isViewed;

  const StoryModel({
    required this.id,
    this.mediaUrl,
    this.mediaType,
    this.modelId,
    this.createdAt,
    this.expiresAt,
    this.isViewed = false,
  });

  /// Полный адрес медиа. Пустая строка, если файла нет.
  String get fullUrl {
    final name = mediaUrl?.trim() ?? '';
    if (name.isEmpty) return '';
    if (name.startsWith('http') || name.startsWith('/')) return name;
    return '$imgUrl$name';
  }

  /// Видео или картинка.
  ///
  /// Сначала локальная переменная, потом проверки: наивный
  /// `mediaUrl!.endsWith(...)` падает на любой записи с `mediaType: IMAGE` и
  /// пустым `mediaUrl`, а из-за short-circuit `||` счастливый путь этого не
  /// ловит — упадёт только в проде на кривой строке.
  bool get isVideo {
    final url = (mediaUrl ?? '').toLowerCase();
    return (mediaType ?? '').toUpperCase() == 'VIDEO' ||
        url.endsWith('.mp4') ||
        url.endsWith('.webm');
  }

  DateTime? get expiresAtDate =>
      expiresAt == null ? null : DateTime.tryParse(expiresAt!);

  /// Локальная проверка срока: между загрузкой ленты и открытием просмотрщика
  /// может пройти время.
  bool get isExpired {
    final expires = expiresAtDate;
    if (expires == null) return false;
    return expires.isBefore(DateTime.now());
  }

  factory StoryModel.fromJson(Map<String, dynamic> json) =>
      _$StoryModelFromJson(json);
  Map<String, dynamic> toJson() => _$StoryModelToJson(this);
}
