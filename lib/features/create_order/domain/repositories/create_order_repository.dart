import '../../data/models/delivery_quote.dart';

/// Результат создания заказа: id заказа (для опроса статуса Kaspi),
/// `redirectUrl` (ссылка Kaspi / QR) и суммы, посчитанные бэком.
/// Любое поле может быть `null`, если бэк его не вернул.
class OrderCreationResult {
  final int? orderId;
  final String? redirectUrl;

  /// Стоимость **только товаров**, без доставки.
  final int? totalPrice;

  /// Цена доставки. Фиксируется в момент создания заказа и уже зашита в
  /// платёжную ссылку — пересчитывать или складывать заново не надо.
  final int? deliveryPrice;

  /// Трек-номер Казпочты вида `AP081184854KZ`. У свежего заказа его ещё нет.
  final String? trackingNumber;

  const OrderCreationResult({
    this.orderId,
    this.redirectUrl,
    this.totalPrice,
    this.deliveryPrice,
    this.trackingNumber,
  });
}

abstract class CreateOrderRepository {
  /// Оформление в два шага: `POST /delivery` (upsert по `cartId` — повторный
  /// вызов просто перезаписывает адрес) и следом `POST /order/new`.
  ///
  /// [deliveryAddress] — ТОЛЬКО улица, без дома; дом и квартира одной строкой
  /// лежат в [houseNumber]. Город бэк берёт из [cityId].
  Future<OrderCreationResult?> createOrder({
    required int cartId,
    required String fullName,
    required String phoneNumber,
    required String postalCode,
    required int cityId,
    required DeliveryMethod deliveryMethod,
    required String deliveryAddress,
    required String houseNumber,
    required String comment,
    required String paymentTypeSlug,
  });

  /// Цены доставки по индексу (`POST /delivery/quote`).
  ///
  /// Дёргать только с готовым 6-значным индексом и с дебаунсом: на ручке
  /// лимит 30 запросов в минуту. `null` — расчёт не удался; чекаут при этом
  /// падать не должен.
  ///
  /// [cityId] обязателен наравне с индексом — бэк считает по паре
  /// «индекс + город», без города вернётся 400.
  Future<DeliveryQuote?> quoteDelivery(String postalCode, int cityId);
}
