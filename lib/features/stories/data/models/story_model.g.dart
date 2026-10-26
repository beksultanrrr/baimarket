// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoryModel _$StoryModelFromJson(Map<String, dynamic> json) => StoryModel(
  id: (json['id'] as num).toInt(),
  mediaUrl: json['mediaUrl'] as String?,
  mediaType: json['mediaType'] as String?,
  modelId: (json['modelId'] as num?)?.toInt(),
  createdAt: json['createdAt'] as String?,
  expiresAt: json['expiresAt'] as String?,
  isViewed: json['isViewed'] as bool? ?? false,
);

Map<String, dynamic> _$StoryModelToJson(StoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mediaUrl': instance.mediaUrl,
      'mediaType': instance.mediaType,
      'modelId': instance.modelId,
      'createdAt': instance.createdAt,
      'expiresAt': instance.expiresAt,
      'isViewed': instance.isViewed,
    };
