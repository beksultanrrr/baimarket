// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewUserModel _$ReviewUserModelFromJson(Map<String, dynamic> json) =>
    ReviewUserModel(
      firstName: json['firstName'] as String?,
      lastNameInitial: json['lastNameInitial'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$ReviewUserModelToJson(ReviewUserModel instance) =>
    <String, dynamic>{
      'firstName': instance.firstName,
      'lastNameInitial': instance.lastNameInitial,
      'avatarUrl': instance.avatarUrl,
    };

ReviewModel _$ReviewModelFromJson(Map<String, dynamic> json) => ReviewModel(
  id: (json['id'] as num).toInt(),
  text: json['text'] as String?,
  rating: (json['rating'] as num?)?.toInt(),
  createdAt: json['createdAt'] as String?,
  user: json['user'] == null
      ? null
      : ReviewUserModel.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ReviewModelToJson(ReviewModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'rating': instance.rating,
      'createdAt': instance.createdAt,
      'user': instance.user?.toJson(),
    };
