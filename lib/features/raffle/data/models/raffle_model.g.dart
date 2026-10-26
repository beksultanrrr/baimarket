// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'raffle_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RaffleModel _$RaffleModelFromJson(Map<String, dynamic> json) => RaffleModel(
  id: (json['id'] as num).toInt(),
  startDate: json['startDate'] as String?,
  endDate: json['endDate'] as String?,
  isActive: json['isActive'] as bool,
  createdAt: json['createdAt'] as String?,
  seller: json['seller'] == null
      ? null
      : SellerModel.fromJson(json['seller'] as Map<String, dynamic>),
  gifts:
      (json['gifts'] as List<dynamic>?)
          ?.map((e) => GiftModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$RaffleModelToJson(RaffleModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt,
      'seller': instance.seller?.toJson(),
      'gifts': instance.gifts.map((e) => e.toJson()).toList(),
    };
