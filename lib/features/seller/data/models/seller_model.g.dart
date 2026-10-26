// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SellerModel _$SellerModelFromJson(Map<String, dynamic> json) => SellerModel(
  id: (json['id'] as num).toInt(),
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  bannerUrl: json['bannerUrl'] as String?,
  description: json['description'] as String?,
  isOwn: json['isOwn'] as bool?,
  raffle: json['raffle'] == null
      ? null
      : SellerRaffleModel.fromJson(json['raffle'] as Map<String, dynamic>),
  ordersCount: (json['ordersCount'] as num?)?.toInt(),
);

Map<String, dynamic> _$SellerModelToJson(SellerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'avatarUrl': instance.avatarUrl,
      'bannerUrl': instance.bannerUrl,
      'description': instance.description,
      'isOwn': instance.isOwn,
      'raffle': instance.raffle?.toJson(),
      'ordersCount': instance.ordersCount,
    };
