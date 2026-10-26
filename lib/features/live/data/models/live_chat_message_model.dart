import 'package:json_annotation/json_annotation.dart';

part 'live_chat_message_model.g.dart';

/// Сообщение чата эфира (`LiveChatMessage` в контракте).
///
/// Приходит тремя путями с одной формой: `snapshot.chat`, событие `chat:new`
/// и `GET /live/:id/chat`.
///
/// Заменяет старую `chat_message.dart`, которая типизировала `id` строкой и
/// читала поле `timestamp` — такого поля сервер не шлёт, поэтому у каждого
/// сообщения молча подставлялось текущее время.
@JsonSerializable()
class LiveChatMessageModel {
  final int id;
  final int? streamId;
  final int? userId;

  @JsonKey(defaultValue: '')
  final String message;

  /// Имя автора. Отдельных `firstName`/`lastName` в этой форме нет.
  final String? fullName;

  /// Имя файла в MinIO. Полный путь — `$imgUrl$avatarUrl`.
  final String? avatarUrl;

  /// В истории всегда `false` — удалённые бэк просто не отдаёт. События
  /// «сообщение удалили» в контракте нет, так что своими силами скрыть его у
  /// уже смотрящих зрителей нельзя: починится на следующем `snapshot`.
  @JsonKey(defaultValue: false)
  final bool isDeleted;

  final int? deletedBy;
  final String? deletedAt;

  /// ISO-строка. Контрактное имя поля — `createdAt`, не `timestamp`.
  final String? createdAt;

  const LiveChatMessageModel({
    required this.id,
    this.streamId,
    this.userId,
    this.message = '',
    this.fullName,
    this.avatarUrl,
    this.isDeleted = false,
    this.deletedBy,
    this.deletedAt,
    this.createdAt,
  });

  DateTime? get createdAtDate =>
      createdAt == null ? null : DateTime.tryParse(createdAt!);

  factory LiveChatMessageModel.fromJson(Map<String, dynamic> json) =>
      _$LiveChatMessageModelFromJson(json);
  Map<String, dynamic> toJson() => _$LiveChatMessageModelToJson(this);
}
