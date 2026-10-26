import 'package:json_annotation/json_annotation.dart';

import '../../../catalog/data/models/category_product_model.dart';

part 'seller_products_response.g.dart';

/// Ответ `GET /seller/:id/models?sort=&limit=&skip=`.
///
/// [total] — **общее** число товаров магазина, а не размер страницы: именно оно
/// идёт в строку «67 товаров».
@JsonSerializable(explicitToJson: true)
class SellerProductsResponse {
  @JsonKey(defaultValue: 0)
  final int total;

  @JsonKey(defaultValue: <CategoryProductModel>[])
  final List<CategoryProductModel> models;

  const SellerProductsResponse({required this.total, required this.models});

  factory SellerProductsResponse.fromJson(Map<String, dynamic> json) =>
      _$SellerProductsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SellerProductsResponseToJson(this);
}
