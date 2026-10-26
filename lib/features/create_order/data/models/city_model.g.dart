// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'city_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CityModel _$CityModelFromJson(Map<String, dynamic> json) => CityModel(
  id: (json['id'] as num).toInt(),
  nameEn: json['nameEn'] as String?,
  nameKz: json['nameKz'] as String?,
  nameRu: json['nameRu'] as String?,
  pickupUrls: (json['pickupUrls'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$CityModelToJson(CityModel instance) => <String, dynamic>{
  'id': instance.id,
  'nameKz': instance.nameKz,
  'nameRu': instance.nameRu,
  'nameEn': instance.nameEn,
  'pickupUrls': instance.pickupUrls,
};
