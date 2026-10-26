part of 'create_order_cubit.dart';

abstract class CreateOrderState extends Equatable {
  const CreateOrderState();

  @override
  List<Object> get props => [];
}

class CreateOrderInitial extends CreateOrderState {}

class OrderCreating extends CreateOrderState {}

class OrderCreated extends CreateOrderState {
  final int? orderId;
  final String? redirectUrl;

  /// Стоимость **только товаров**, без доставки.
  final int? totalPrice;

  /// Цена доставки из корня заказа. Уже зашита в платёжную ссылку, поэтому
  /// к оплате = [totalPrice] + [deliveryPrice], и складывать что-то ещё не надо.
  final int? deliveryPrice;

  /// Трек-номер Казпочты вида `AP081184854KZ`. У свежего заказа его ещё нет.
  final String? trackingNumber;

  const OrderCreated({
    this.orderId,
    this.redirectUrl,
    this.totalPrice,
    this.deliveryPrice,
    this.trackingNumber,
  });

  @override
  List<Object> get props => [
    orderId ?? -1,
    redirectUrl ?? '',
    totalPrice ?? -1,
    deliveryPrice ?? -1,
    trackingNumber ?? '',
  ];
}

class OrderCreateError extends CreateOrderState {
  final String? message;
  const OrderCreateError({this.message});

  @override
  List<Object> get props => [message ?? ''];
}

// ---------------------------------------------------------------------------
// Состояния расчёта доставки — отдельная ветка под [DeliveryQuoteCubit].
// Живут в своём кубите, поэтому ответ `/delivery/quote` не затирает
// OrderCreating/OrderCreated.
// ---------------------------------------------------------------------------

abstract class DeliveryQuoteState extends Equatable {
  const DeliveryQuoteState();

  @override
  List<Object> get props => [];
}

/// Считать нечего: индекс пустой или ещё не дописан до шести цифр.
/// UI в этот момент показывает `enterPostalForDelivery`.
class DeliveryQuoteIdle extends DeliveryQuoteState {
  const DeliveryQuoteIdle();
}

/// Запрос ушёл — UI показывает `deliveryPriceCalculating`.
class DeliveryQuoteLoading extends DeliveryQuoteState {
  final String postalCode;
  const DeliveryQuoteLoading({required this.postalCode});

  @override
  List<Object> get props => [postalCode];
}

/// Успешный расчёт. Бэк обещает ровно два варианта в порядке BRANCH, DOOR;
/// признака «по умолчанию» нет — выбор делает покупатель.
class DeliveryQuoteLoaded extends DeliveryQuoteState {
  final String postalCode;
  final DeliveryQuote quote;
  const DeliveryQuoteLoaded({required this.postalCode, required this.quote});

  /// Варианты в том порядке, в котором их прислал бэк.
  List<DeliveryOption> get options => quote.options;

  /// Цена под конкретный способ, `null` — если такого варианта не пришло.
  int? priceFor(DeliveryMethod method) => quote.optionFor(method)?.price;

  // Сравниваем по содержимому: повторный одинаковый ответ не должен
  // считаться новым состоянием (DeliveryQuote — не Equatable).
  @override
  List<Object> get props => [
    postalCode,
    quote.weightGrams,
    quote.options.map((o) => '${o.method.wire}=${o.price}').join(','),
  ];
}

/// Расчёт не удался (400/429/сеть/пустые опции). Текст пишет UI —
/// `deliveryQuoteFailed`; повтор — [DeliveryQuoteCubit.retryQuote].
class DeliveryQuoteError extends DeliveryQuoteState {
  final String postalCode;
  const DeliveryQuoteError({required this.postalCode});

  @override
  List<Object> get props => [postalCode];
}
