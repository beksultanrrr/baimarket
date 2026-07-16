/// Результат создания заказа: id заказа (для опроса статуса Kaspi)
/// и `redirectUrl` (ссылка Kaspi / QR). Любое поле может быть `null`,
/// если бэк его не вернул.
class OrderCreationResult {
  final int? orderId;
  final String? redirectUrl;
  const OrderCreationResult({this.orderId, this.redirectUrl});
}

abstract class CreateOrderRepository {
  Future<OrderCreationResult?> createOrder({
    required int cartId,
    required String fullName,
    required String phoneNumber,
    required bool selfPick,
    required String postalCode,
    required int cityId,
    required String deliveryAddress,
    required String comment,
    required String? pickupUrl,
    required String? selfPickDate,
    required int? filialId,
    required String paymentTypeSlug,
  });
}
