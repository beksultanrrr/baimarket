import 'package:json_annotation/json_annotation.dart';

import '../../../product/data/models/product_model.dart';

part 'cart_item_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CartItemModel {
  /// **id позиции**, именно он идёт в `DELETE /cartitem/:id`.
  /// `model.id` для удаления не подходит — это `modelId`.
  final int id;

  int quantity;
  final int? totalPrice;

  /// Цена за единицу и сумма по позиции без скидок — приходят с сервера уже
  /// пересчитанными по актуальному прайсу.
  final int? unitPrice;
  final int? unitOldPrice;
  final int? totalOldPrice;

  final ProductModel? model;

  CartItemModel({
    required this.id,
    required this.totalPrice,
    required this.model,
    required this.quantity,
    this.unitPrice,
    this.unitOldPrice,
    this.totalOldPrice,
  });
  factory CartItemModel.fromJson(Map<String, dynamic> json) =>
      _$CartItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$CartItemModelToJson(this);
}
