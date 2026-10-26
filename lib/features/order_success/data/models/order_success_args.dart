import '../../../cards/data/models/payment_card_model.dart';

/// Аргументы success-экрана `/order_success`.
class OrderSuccessArgs {
  final int orderId;
  final int itemsTotal;
  final int? oldTotal;
  final int savings;
  final int ticketsEarned;
  final String? deliveryAddressLine;
  final String? deliveryPostalCode;
  final List<String> productImageUrls;

  /// Цена доставки из заказа. У старых заказов 0 — тогда разбивку не показываем.
  final int deliveryPrice;

  /// Трек-номер Казпочты вида "AP081184854KZ". `null`, пока заказ не отправлен.
  final String? trackingNumber;

  /// Бренд использованной карты (visa / mastercard) — для строки «Способ оплаты».
  /// `null`, если оплата картой не картой (e.g. kaspi/halyk).
  final PaymentCardBrand? cardBrand;

  const OrderSuccessArgs({
    required this.orderId,
    required this.itemsTotal,
    this.oldTotal,
    this.savings = 0,
    this.ticketsEarned = 0,
    this.deliveryAddressLine,
    this.deliveryPostalCode,
    this.productImageUrls = const [],
    this.deliveryPrice = 0,
    this.trackingNumber,
    this.cardBrand,
  });
}
