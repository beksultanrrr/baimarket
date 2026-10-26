// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartItemModel _$CartItemModelFromJson(Map<String, dynamic> json) =>
    CartItemModel(
      id: (json['id'] as num).toInt(),
      totalPrice: (json['totalPrice'] as num?)?.toInt(),
      model: json['model'] == null
          ? null
          : ProductModel.fromJson(json['model'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unitPrice'] as num?)?.toInt(),
      unitOldPrice: (json['unitOldPrice'] as num?)?.toInt(),
      totalOldPrice: (json['totalOldPrice'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CartItemModelToJson(CartItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'quantity': instance.quantity,
      'totalPrice': instance.totalPrice,
      'unitPrice': instance.unitPrice,
      'unitOldPrice': instance.unitOldPrice,
      'totalOldPrice': instance.totalOldPrice,
      'model': instance.model?.toJson(),
    };
