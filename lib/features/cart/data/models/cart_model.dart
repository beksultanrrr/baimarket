import 'package:json_annotation/json_annotation.dart';
import 'cart_item_model.dart';

part 'cart_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CartModel {
  final int id;
  final int userId;
  final int? totalPrice;

  /// Сумма без скидок. `GET /cart` перезаписывает цены позиций на актуальные,
  /// поэтому итог надо брать с сервера, а не считать локально из `model.price` —
  /// иначе после изменения цены пользователь увидит одну сумму, а заплатит
  /// другую.
  final int? oldTotalPrice;

  final List<CartItemModel>? cartItems;
  final Map<String, dynamic>? deliveryInfo;

  CartModel({
    required this.id,
    required this.cartItems,
    required this.totalPrice,
    required this.userId,
    required this.deliveryInfo,
    this.oldTotalPrice,
  });
  factory CartModel.fromJson(Map<String, dynamic> json) =>
      _$CartModelFromJson(json);
  Map<String, dynamic> toJson() => _$CartModelToJson(this);
}
