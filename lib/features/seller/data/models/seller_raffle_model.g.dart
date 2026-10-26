// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_raffle_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SellerRaffleModel _$SellerRaffleModelFromJson(Map<String, dynamic> json) =>
    SellerRaffleModel(
      id: (json['id'] as num?)?.toInt(),
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
    );

Map<String, dynamic> _$SellerRaffleModelToJson(SellerRaffleModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
    };
