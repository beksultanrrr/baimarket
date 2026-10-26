import '../../../cards/data/models/payment_card_model.dart';

/// Аргументы экрана оплаты `/payment`. Передаётся через `state.extra`.
class PaymentArgs {
  final int amount;
  final int commission;
  final String? paymentUrl;

  // Контекст заказа (нужен для success-экрана и чека).
  final int? itemsTotal;
  final int? oldTotal;
  final int? savings;
  final int? ticketsEarned;
  final String? deliveryAddressLine;
  final String? deliveryPostalCode;
  final List<String> productImageUrls;

  /// Цена доставки, посчитанная бэком при создании заказа.
  /// К оплате = itemsTotal + deliveryPrice, сами ничего не считаем.
  final int deliveryPrice;

  /// Способ доставки в wire-формате — 'BRANCH' или 'DOOR'.
  final String? deliveryMethod;

  /// Id созданного заказа — нужен success-экрану и повторной оплате.
  final int? orderId;

  /// Бренд выбранной карты — заполняется когда уходим на WebView
  /// банка, чтобы success-экран показал правильный VISA/MasterCard.
  final PaymentCardBrand? cardBrand;

  const PaymentArgs({
    required this.amount,
    this.commission = 0,
    this.paymentUrl,
    this.itemsTotal,
    this.oldTotal,
    this.savings,
    this.ticketsEarned,
    this.deliveryAddressLine,
    this.deliveryPostalCode,
    this.productImageUrls = const [],
    this.deliveryPrice = 0,
    this.deliveryMethod,
    this.orderId,
    this.cardBrand,
  });

  PaymentArgs copyWith({
    PaymentCardBrand? cardBrand,
    int? deliveryPrice,
    String? deliveryMethod,
    int? orderId,
  }) =>
      PaymentArgs(
        amount: amount,
        commission: commission,
        paymentUrl: paymentUrl,
        itemsTotal: itemsTotal,
        oldTotal: oldTotal,
        savings: savings,
        ticketsEarned: ticketsEarned,
        deliveryAddressLine: deliveryAddressLine,
        deliveryPostalCode: deliveryPostalCode,
        productImageUrls: productImageUrls,
        deliveryPrice: deliveryPrice ?? this.deliveryPrice,
        deliveryMethod: deliveryMethod ?? this.deliveryMethod,
        orderId: orderId ?? this.orderId,
        cardBrand: cardBrand ?? this.cardBrand,
      );
}
