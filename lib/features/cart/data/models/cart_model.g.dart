// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartModel _$CartModelFromJson(Map<String, dynamic> json) => CartModel(
  id: (json['id'] as num).toInt(),
  cartItems: (json['cartItems'] as List<dynamic>?)
      ?.map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalPrice: (json['totalPrice'] as num?)?.toInt(),
  userId: (json['userId'] as num).toInt(),
  deliveryInfo: json['deliveryInfo'] as Map<String, dynamic>?,
  oldTotalPrice: (json['oldTotalPrice'] as num?)?.toInt(),
);

Map<String, dynamic> _$CartModelToJson(CartModel instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'totalPrice': instance.totalPrice,
  'oldTotalPrice': instance.oldTotalPrice,
  'cartItems': instance.cartItems?.map((e) => e.toJson()).toList(),
  'deliveryInfo': instance.deliveryInfo,
};
