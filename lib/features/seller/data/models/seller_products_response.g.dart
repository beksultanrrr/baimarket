// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_products_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SellerProductsResponse _$SellerProductsResponseFromJson(
  Map<String, dynamic> json,
) => SellerProductsResponse(
  total: (json['total'] as num?)?.toInt() ?? 0,
  models:
      (json['models'] as List<dynamic>?)
          ?.map((e) => CategoryProductModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$SellerProductsResponseToJson(
  SellerProductsResponse instance,
) => <String, dynamic>{
  'total': instance.total,
  'models': instance.models.map((e) => e.toJson()).toList(),
};
