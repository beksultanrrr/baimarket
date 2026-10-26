import 'dart:async';

import 'package:bai_market/core/services/order_logger.dart';
import 'package:bai_market/features/create_order/data/datasources/create_order_services.dart';
import 'package:bai_market/features/create_order/data/models/delivery_quote.dart';
import 'package:bai_market/features/create_order/domain/repositories/create_order_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'create_order_state.dart';

/// Оформление заказа. Расчёт доставки вынесен в дочерний кубит [quote]:
/// котировка и создание заказа идут независимо, и состояние одного не должно
/// затирать состояние другого (иначе ответ `/delivery/quote` сбрасывал бы
/// `OrderCreating`, на котором висит BlocListener страницы).
class CreateOrderCubit extends Cubit<CreateOrderState> {
  final CreateOrderRepository _createOrderRepository;

  /// Кубит расчёта доставки. Создаётся и закрывается вместе с родителем,
  /// поэтому дебаунс переживает пересборку виджетов. В UI подключается явно,
  /// без провайдера:
  /// `BlocBuilder<DeliveryQuoteCubit, DeliveryQuoteState>(bloc: cubit.quote, …)`.
  late final DeliveryQuoteCubit quote;

  CreateOrderCubit({CreateOrderRepository? createOrderRepository})
    : _createOrderRepository = createOrderRepository ?? CreateOrderServices(),
      super(CreateOrderInitial()) {
    quote = DeliveryQuoteCubit(createOrderRepository: _createOrderRepository);
  }

  void reset() {
    orderLog.state('reset() → CreateOrderInitial');
    quote.reset();
    emit(CreateOrderInitial());
  }

  /// Сокращение до [DeliveryQuoteCubit.loadQuote] — чтобы страница не тянула
  /// дочерний кубит ради одного вызова. Ждать этот `Future` смысла нет: он
  /// завершается после постановки дебаунса, а не после ответа сервера,
  /// результат приходит состоянием в [quote].
  Future<void> loadQuote(String postalCode, int? cityId) =>
      quote.loadQuote(postalCode, cityId);

  /// [deliveryAddress] — ТОЛЬКО улица; дом и квартира одной строкой лежат
  /// в [houseNumber]. Город бэк берёт из [cityId].
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
  }) async {
    orderLog.step(
      'createOrder() called',
      'cartId=$cartId, fullName="$fullName", phone="$phoneNumber", '
          'postalCode="$postalCode", cityId=$cityId, '
          'deliveryMethod=${deliveryMethod.wire}, '
          'deliveryAddress="$deliveryAddress", houseNumber="$houseNumber", '
          'paymentTypeSlug=$paymentTypeSlug',
    );
    orderLog.state('emit OrderCreating');
    emit(OrderCreating());
    try {
      final res = await _createOrderRepository.createOrder(
        cartId: cartId,
        fullName: fullName,
        phoneNumber: phoneNumber,
        postalCode: postalCode,
        cityId: cityId,
        deliveryMethod: deliveryMethod,
        deliveryAddress: deliveryAddress,
        houseNumber: houseNumber,
        comment: comment,
        paymentTypeSlug: paymentTypeSlug,
      );
      if (res != null) {
        orderLog.state(
          'emit OrderCreated',
          'orderId=${res.orderId}, redirectUrl="${res.redirectUrl}", '
              'totalPrice=${res.totalPrice}, deliveryPrice=${res.deliveryPrice}, '
              'trackingNumber=${res.trackingNumber}',
        );
        emit(OrderCreated(
          orderId: res.orderId,
          redirectUrl: res.redirectUrl,
          totalPrice: res.totalPrice,
          deliveryPrice: res.deliveryPrice,
          trackingNumber: res.trackingNumber,
        ));
      } else {
        orderLog.state('emit OrderCreateError (res == null)');
        emit(const OrderCreateError());
      }
      return res;
    } on OrderCreationException catch (e, st) {
      orderLog.error('OrderCreationException → emit error', e.message, e, st);
      emit(OrderCreateError(message: e.message));
      return null;
    } catch (e, st) {
      orderLog.error('createOrder cubit-level exception', e.toString(), e, st);
      emit(const OrderCreateError());
      return null;
    }
  }

  @override
  Future<void> close() async {
    await quote.close();
    await super.close();
  }
}

/// Расчёт стоимости доставки по индексу (`POST /delivery/quote`).
///
/// Дебаунс держим здесь, а не в виджете: пересборка страницы не должна
/// сбрасывать таймер, иначе на ручке легко упереться в лимит 30 запросов
/// в минуту. Запрос уходит только с готовым 6-значным индексом.
class DeliveryQuoteCubit extends Cubit<DeliveryQuoteState> {
  final CreateOrderRepository _createOrderRepository;

  DeliveryQuoteCubit({CreateOrderRepository? createOrderRepository})
    : _createOrderRepository = createOrderRepository ?? CreateOrderServices(),
      super(const DeliveryQuoteIdle());

  /// Индекс — ровно шесть цифр, иначе бэк отдаст 400.
  static final RegExp _postalCodeRe = RegExp(r'^\d{6}$');

  /// Пауза после последнего нажатия. Полсекунды хватает, чтобы ввод индекса
  /// целиком уложился в один запрос.
  static const _debounceDuration = Duration(milliseconds: 500);

  Timer? _debounce;

  /// Последний индекс и город, ушедшие (или уходящие) в запрос — по этой
  /// паре отбрасываем устаревшие ответы.
  String _lastRequested = '';
  int? _lastCityId;

  /// Дёргать на каждое изменение поля индекса И при смене адреса: расчёт
  /// идёт по паре «индекс + город», поэтому смена города обязана его
  /// перезапустить. Невалидный ввод просто гасит расчёт, валидный ставится
  /// в дебаунс. Сеть здесь не ждётся.
  Future<void> loadQuote(String postalCode, int? cityId) async {
    final code = postalCode.trim();
    _debounce?.cancel();

    if (!_postalCodeRe.hasMatch(code) || cityId == null) {
      // Индекс ещё не дописан или адрес не выбран — молча ждём, подсказку
      // рисует UI.
      _lastRequested = '';
      _lastCityId = null;
      if (state is! DeliveryQuoteIdle) {
        orderLog.state(
          'emit DeliveryQuoteIdle',
          'postalCode="$code", cityId=$cityId',
        );
        emit(const DeliveryQuoteIdle());
      }
      return;
    }

    // Та же пара уже посчитана или считается — второй раз не ходим.
    // Город сверяем по `_lastCityId`: в состоянии лежит только индекс, и без
    // этой проверки смена города при том же индексе не перезапросила бы цену.
    final current = state;
    final sameCity = cityId == _lastCityId;
    if (sameCity && current is DeliveryQuoteLoaded && current.postalCode == code) return;
    if (sameCity && current is DeliveryQuoteLoading && current.postalCode == code) return;

    _debounce = Timer(_debounceDuration, () => _runQuote(code, cityId));
  }

  /// Повтор после [DeliveryQuoteError] — без дебаунса, по кнопке
  /// «попробовать ещё раз».
  Future<void> retryQuote() async {
    final code = _lastRequested;
    final cityId = _lastCityId;
    if (!_postalCodeRe.hasMatch(code) || cityId == null) return;
    _debounce?.cancel();
    await _runQuote(code, cityId);
  }

  /// Сброс при выходе из аккаунта и при закрытии чекаута.
  void reset() {
    _debounce?.cancel();
    _lastRequested = '';
    _lastCityId = null;
    if (!isClosed && state is! DeliveryQuoteIdle) {
      orderLog.state('quote reset → DeliveryQuoteIdle');
      emit(const DeliveryQuoteIdle());
    }
  }

  Future<void> _runQuote(String code, int cityId) async {
    if (isClosed) return;
    _lastRequested = code;
    _lastCityId = cityId;
    orderLog.api('POST /delivery/quote', 'postalCode="$code", cityId=$cityId');
    emit(DeliveryQuoteLoading(postalCode: code));

    DeliveryQuote? quote;
    try {
      // Репозиторий ошибок не бросает и на любой неудаче отдаёт null,
      // но чекаут не должен падать даже если это когда-нибудь изменится.
      quote = await _createOrderRepository.quoteDelivery(code, cityId);
    } catch (e, st) {
      orderLog.error('quoteDelivery threw', 'postalCode="$code"', e, st);
      quote = null;
    }

    if (isClosed) return;
    // Пока ходили, индекс или город успели поменять — ответ уже не нужен.
    if (code != _lastRequested || cityId != _lastCityId) {
      orderLog.info('stale quote discarded', '"$code" vs "$_lastRequested"');
      return;
    }

    if (quote == null || quote.options.isEmpty) {
      orderLog.state('emit DeliveryQuoteError', 'postalCode="$code"');
      emit(DeliveryQuoteError(postalCode: code));
      return;
    }

    orderLog.state(
      'emit DeliveryQuoteLoaded',
      'postalCode="$code", weight=${quote.weightGrams}g, '
          'options=${quote.options}',
    );
    emit(DeliveryQuoteLoaded(postalCode: code, quote: quote));
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
