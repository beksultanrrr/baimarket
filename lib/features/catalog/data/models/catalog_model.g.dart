// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CatalogModel _$CatalogModelFromJson(Map<String, dynamic> json) => CatalogModel(
  id: (json['id'] as num).toInt(),
  nameKz: json['nameKz'] as String?,
  nameRu: json['nameRu'] as String?,
  nameEn: json['nameEn'] as String?,
  models: (json['models'] as List<dynamic>)
      .map((e) => CategoryProductModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CatalogModelToJson(CatalogModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nameKz': instance.nameKz,
      'nameRu': instance.nameRu,
      'nameEn': instance.nameEn,
      'models': instance.models,
    };
