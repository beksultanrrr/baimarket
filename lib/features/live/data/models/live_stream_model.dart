import 'package:json_annotation/json_annotation.dart';

import 'live_product_card_model.dart';

part 'live_stream_model.g.dart';

/// Продавец, ведущий эфир. Приходит вложенным в `GET /live`, `GET /live/:id`.
///
/// Своя модель, а не `features/seller/.../seller_model.dart`: там `id`
/// обязателен и тянется `raffle`, а здесь бэк отдаёт всего четыре поля и
/// «эфир без продавца» — валидное состояние (`POST /live/start` кладёт
/// `stream` без `seller`).
@JsonSerializable()
class LiveStreamSellerModel {
  final int id;
  final String? firstName;
  final String? lastName;

  /// Имя файла в MinIO. Полный путь — `$imgUrl$avatarUrl`.
  final String? avatarUrl;

  const LiveStreamSellerModel({
    required this.id,
    this.firstName,
    this.lastName,
    this.avatarUrl,
  });

  /// «Ырысбала Икрамбай» — пустые части отбрасываются.
  String get displayName => [firstName, lastName]
      .whereType<String>()
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .join(' ');

  factory LiveStreamSellerModel.fromJson(Map<String, dynamic> json) =>
      _$LiveStreamSellerModelFromJson(json);
  Map<String, dynamic> toJson() => _$LiveStreamSellerModelToJson(this);
}

/// Эфир (`LiveStream` в контракте).
///
/// Одна модель на все ручки — набор ключей отличается, поэтому всё кроме `id`
/// либо nullable, либо с дефолтом:
/// * `GET /live` → плюс `seller` и `pinnedModel`;
/// * `GET /live/:id` → то же;
/// * `GET /live/my` → плюс `pinnedModel`, но без `seller`;
/// * `POST /live/start` → без `seller` и `pinnedModel`.
@JsonSerializable(explicitToJson: true)
class LiveStreamModel {
  final int id;
  final int? sellerId;

  /// Имя комнаты LiveKit. Нужно только для отладки — подключение идёт по
  /// `url` + `token`, а не по имени.
  final String? roomName;

  final String? title;

  /// `LIVE` или `ENDED`. Намеренно строка, а не enum: неизвестное значение с
  /// сервера не должно ронять `fromJson`.
  final String? status;

  /// ISO-строки. `DateTime` здесь не используем — сгенерированный
  /// `DateTime.parse(...)` бросает внутри socket-хендлера, где ловить некому.
  final String? startedAt;
  final String? endedAt;
  final String? createdAt;
  final String? updatedAt;

  /// Текущие зрители. Считается по вебхукам LiveKit (без самого продавца),
  /// поэтому отстаёт и у свежего эфира честно равен нулю.
  @JsonKey(defaultValue: 0)
  final int viewerCount;

  @JsonKey(defaultValue: 0)
  final int peakViewerCount;

  @JsonKey(defaultValue: 0)
  final int totalMessages;

  final int? pinnedModelId;

  /// Имя файла обложки в MinIO. Может быть `null` — тогда берём фото
  /// закреплённого товара, см. `liveCoverImageUrl` в `live_media.dart`.
  final String? coverUrl;

  final LiveStreamSellerModel? seller;

  /// Товар, который сейчас на экране.
  final LiveProductCardModel? pinnedModel;

  const LiveStreamModel({
    required this.id,
    this.sellerId,
    this.roomName,
    this.title,
    this.status,
    this.startedAt,
    this.endedAt,
    this.createdAt,
    this.updatedAt,
    this.viewerCount = 0,
    this.peakViewerCount = 0,
    this.totalMessages = 0,
    this.pinnedModelId,
    this.coverUrl,
    this.seller,
    this.pinnedModel,
  });

  bool get isLive => (status ?? '').toUpperCase() == 'LIVE';

  DateTime? get startedAtDate =>
      startedAt == null ? null : DateTime.tryParse(startedAt!);

  factory LiveStreamModel.fromJson(Map<String, dynamic> json) =>
      _$LiveStreamModelFromJson(json);
  Map<String, dynamic> toJson() => _$LiveStreamModelToJson(this);
}
