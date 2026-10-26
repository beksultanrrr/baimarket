// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reviews_page_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewsPageResponse _$ReviewsPageResponseFromJson(Map<String, dynamic> json) =>
    ReviewsPageResponse(
      total: (json['total'] as num?)?.toInt() ?? 0,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$ReviewsPageResponseToJson(
  ReviewsPageResponse instance,
) => <String, dynamic>{
  'total': instance.total,
  'items': instance.items.map((e) => e.toJson()).toList(),
};
