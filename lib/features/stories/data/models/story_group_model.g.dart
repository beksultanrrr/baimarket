// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_group_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoryGroupModel _$StoryGroupModelFromJson(Map<String, dynamic> json) =>
    StoryGroupModel(
      seller: SellerModel.fromJson(json['seller'] as Map<String, dynamic>),
      hasUnviewed: json['hasUnviewed'] as bool? ?? false,
      stories:
          (json['stories'] as List<dynamic>?)
              ?.map((e) => StoryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$StoryGroupModelToJson(StoryGroupModel instance) =>
    <String, dynamic>{
      'seller': instance.seller.toJson(),
      'hasUnviewed': instance.hasUnviewed,
      'stories': instance.stories.map((e) => e.toJson()).toList(),
    };
