// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryProductModel _$CategoryProductModelFromJson(
  Map<String, dynamic> json,
) => CategoryProductModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String?,
  price: (json['price'] as num?)?.toInt(),
  oldPrice: (json['oldPrice'] as num?)?.toInt(),
  photoUrls: (json['photoUrls'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  inStockCount: (json['inStockCount'] as num?)?.toInt(),
  descriptionKz: json['descriptionKz'] as String?,
  descriptionRu: json['descriptionRu'] as String?,
  descriptionEn: json['descriptionEn'] as String?,
  collections: (json['collections'] as List<dynamic>?)
      ?.map((e) => CollectionBadgeModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  isInFavorite: json['isInFavorite'] as bool? ?? false,
  plusPrice: (json['plusPrice'] as num?)?.toInt(),
  ticketsCount: (json['ticketsCount'] as num?)?.toInt(),
  cartQuantity: (json['cartQuantity'] as num?)?.toInt(),
);

Map<String, dynamic> _$CategoryProductModelToJson(
  CategoryProductModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'price': instance.price,
  'oldPrice': instance.oldPrice,
  'photoUrls': instance.photoUrls,
  'inStockCount': instance.inStockCount,
  'descriptionKz': instance.descriptionKz,
  'descriptionRu': instance.descriptionRu,
  'descriptionEn': instance.descriptionEn,
  'collections': instance.collections?.map((e) => e.toJson()).toList(),
  'isInFavorite': instance.isInFavorite,
  'plusPrice': instance.plusPrice,
  'ticketsCount': instance.ticketsCount,
  'cartQuantity': instance.cartQuantity,
};
