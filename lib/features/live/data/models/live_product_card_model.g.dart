// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_product_card_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiveProductCardModel _$LiveProductCardModelFromJson(
  Map<String, dynamic> json,
) => LiveProductCardModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String?,
  price: json['price'] as num?,
  oldPrice: json['oldPrice'] as num?,
  plusPrice: json['plusPrice'] as num?,
  photoUrls: (json['photoUrls'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$LiveProductCardModelToJson(
  LiveProductCardModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'price': instance.price,
  'oldPrice': instance.oldPrice,
  'plusPrice': instance.plusPrice,
  'photoUrls': instance.photoUrls,
};
