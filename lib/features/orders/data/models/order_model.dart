import 'package:json_annotation/json_annotation.dart';

import 'order_product_model.dart';

part 'order_model.g.dart';

@JsonSerializable()
class OrderModel {
  final int id;
  final int userId;
  final String? trackingNumber;
  final String? paymentUrl;
  final String? paymentTypeSlug;
  final String? paymentFailureReason;
  final String? paymentId;
  final List<OrderProductModel> cartItems;
  final Map<String, dynamic>? deliveryInfo;
  final String createdAt;
  final int totalPrice;

  /// Цена доставки. Бэк всегда присылает ключ (@default(0), NOT NULL),
  /// дефолт оставлен страховкой — без него null уронил бы парсинг.
  @JsonKey(defaultValue: 0)
  final int deliveryPrice;
  final String? status;

  OrderModel({
    required this.id,
    required this.cartItems,
    required this.totalPrice,
    required this.deliveryPrice,
    required this.userId,
    required this.deliveryInfo,
    required this.createdAt,
    required this.paymentFailureReason,
    required this.paymentId,
    required this.paymentTypeSlug,
    required this.paymentUrl,
    required this.status,
    required this.trackingNumber,
  });
  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);
  Map<String, dynamic> toJson() => _$OrderModelToJson(this);
}
