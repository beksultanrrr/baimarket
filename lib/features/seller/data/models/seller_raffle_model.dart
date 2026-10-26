import 'package:json_annotation/json_annotation.dart';

part 'seller_raffle_model.g.dart';

/// Активный розыгрыш продавца — вложенный объект `raffle` в `GET /seller`.
///
/// Бэк гарантирует не более одного активного розыгрыша на продавца. Если
/// розыгрыш не заведён, поле приходит как `null`.
@JsonSerializable()
class SellerRaffleModel {
  final int? id;

  /// ISO-строки. `endDate` — это дата на плашке карточки магазина; если она
  /// `null`, плашку показывать не нужно.
  final String? startDate;
  final String? endDate;

  const SellerRaffleModel({this.id, this.startDate, this.endDate});

  factory SellerRaffleModel.fromJson(Map<String, dynamic> json) =>
      _$SellerRaffleModelFromJson(json);
  Map<String, dynamic> toJson() => _$SellerRaffleModelToJson(this);
}
