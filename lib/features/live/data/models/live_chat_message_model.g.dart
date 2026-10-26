// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_chat_message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiveChatMessageModel _$LiveChatMessageModelFromJson(
  Map<String, dynamic> json,
) => LiveChatMessageModel(
  id: (json['id'] as num).toInt(),
  streamId: (json['streamId'] as num?)?.toInt(),
  userId: (json['userId'] as num?)?.toInt(),
  message: json['message'] as String? ?? '',
  fullName: json['fullName'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  isDeleted: json['isDeleted'] as bool? ?? false,
  deletedBy: (json['deletedBy'] as num?)?.toInt(),
  deletedAt: json['deletedAt'] as String?,
  createdAt: json['createdAt'] as String?,
);

Map<String, dynamic> _$LiveChatMessageModelToJson(
  LiveChatMessageModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'streamId': instance.streamId,
  'userId': instance.userId,
  'message': instance.message,
  'fullName': instance.fullName,
  'avatarUrl': instance.avatarUrl,
  'isDeleted': instance.isDeleted,
  'deletedBy': instance.deletedBy,
  'deletedAt': instance.deletedAt,
  'createdAt': instance.createdAt,
};
