// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection_badge_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CollectionBadgeModel _$CollectionBadgeModelFromJson(
  Map<String, dynamic> json,
) => CollectionBadgeModel(
  id: (json['id'] as num?)?.toInt(),
  slug: json['slug'] as String?,
  labelUrl: json['labelUrl'] as String?,
  color: json['color'] as String?,
  discount: (json['discount'] as num?)?.toInt(),
  nameKz: json['nameKz'] as String?,
  nameRu: json['nameRu'] as String?,
  nameEn: json['nameEn'] as String?,
  name: json['name'] as String?,
);

Map<String, dynamic> _$CollectionBadgeModelToJson(
  CollectionBadgeModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'slug': instance.slug,
  'labelUrl': instance.labelUrl,
  'color': instance.color,
  'discount': instance.discount,
  'nameKz': instance.nameKz,
  'nameRu': instance.nameRu,
  'nameEn': instance.nameEn,
  'name': instance.name,
};
