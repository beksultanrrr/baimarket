import 'dart:async';

import 'package:bai_market/features/cart/data/models/cart_change_model.dart';
import 'package:bai_market/features/cart/data/models/cart_item_model.dart';
import 'package:bai_market/features/cart/data/models/cart_model.dart';
import 'package:bai_market/features/cart/data/services/cart_services.dart';
import 'package:bai_market/features/cart/domain/repositories/cart_repository.dart';
import 'package:bai_market/core/secure_token_storage.dart';
import 'package:bai_market/core/services/app_logger.dart';
import 'package:bai_market/features/product/data/models/product_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'cart_state.dart';

sealed class CartEvent {
  const CartEvent();
}

class CartAddFailedEvent extends CartEvent {
  const CartAddFailedEvent();
}

class CartRemoveFailedEvent extends CartEvent {
  const CartRemoveFailedEvent();
}

class CartAddUnauthenticatedEvent extends CartEvent {
  final int productId;
  const CartAddUnauthenticatedEvent(this.productId);
}

/// Сервер отказал осмысленно — «нет столько на складе», «товар не найден».
/// Раньше такие ответы схлопывались в общий [CartAddFailedEvent] и причина
/// до пользователя не доходила.
class CartWriteRejectedEvent extends CartEvent {
  const CartWriteRejectedEvent(this.message, this.statusCode);
  final String message;
  final int? statusCode;
}

/// Уменьшение количества не атомарно: позицию удалили, а добавить заново с
/// новым количеством не удалось. Молчать тут нельзя — товар пропал из корзины.
class CartQuantityChangeFailedEvent extends CartEvent {
  const CartQuantityChangeFailedEvent();
}

class CartClearFailedEvent extends CartEvent {
  const CartClearFailedEvent();
}

class CartRefreshFailedEvent extends CartEvent {
  const CartRefreshFailedEvent();
}

/// `GET /cart` синхронизировал корзину с каталогом: что-то закончилось или
/// изменилось в цене.
class CartChangesEvent extends CartEvent {
  const CartChangesEvent(this.changes);
  final List<CartChangeModel> changes;
}

/// На оформление ушли с пустой корзиной.
class CartEmptyOnCheckoutEvent extends CartEvent {
  const CartEmptyOnCheckoutEvent();
}

/// Корзина.
///
/// Источник истины — сервер: и `POST /cart`, и `GET /cart` возвращают полную
/// актуальную корзину, поэтому ответ **цитируется**, а не сливается с локальным
/// состоянием.
///
/// Оптимистично применяется только добавление: оно происходит в скролле сетки и
/// должно быть мгновенным, а ответ сервера через несколько сотен миллисекунд
/// заменяет предсказание авторитетным значением. Уменьшение, удаление и очистка
/// многозапросные, их предсказание может оказаться просто неверным — там
/// показываем индикатор занятости и применяем только ответ сервера.
class CartCubit extends Cubit<CartState> {
  final CartRepository _cartRepository;
  final _events = StreamController<CartEvent>.broadcast();

  CartModel? _cart;
  List<CartChangeModel> _changes = const [];

  /// Счётчик поколений. Любая запись его увеличивает; любое чтение
  /// запоминает значение до await и **выбрасывает результат**, если к моменту
  /// ответа поколение сменилось.
  ///
  /// Это и есть защита от бага «очистил корзину, добавил товар — вернулись
  /// старые»: `GET /cart`, улетевший до нажатия «Очистить», физически не может
  /// примениться после неё.
  int _epoch = 0;

  /// Однополосная очередь мутаций: два запроса уменьшения не должны
  /// перемешаться с добавлением, а `DELETE /cart` — оказаться между `POST` и
  /// разбором его ответа.
  Future<void> _chain = Future.value();

  /// Позиции с летящим запросом — по ним UI дизейблит кнопки.
  final Set<int> _busyLines = {};

  bool _busy = false;
  bool _loadedOnce = false;
  Future<void>? _inFlightGet;

  CartCubit({CartRepository? cartRepository})
      : _cartRepository = cartRepository ?? CartServices(),
        super(CartInitial());

  Stream<CartEvent> get events => _events.stream;

  // ── чтение состояния ──────────────────────────────────────────────────────

  int quantityOf(int productId) {
    for (final item in _cart?.cartItems ?? const <CartItemModel>[]) {
      if (item.model?.id == productId) return item.quantity;
    }
    return 0;
  }

  /// id позиции корзины (`cartItems[].id`) по id товара — именно он идёт в
  /// `DELETE /cartitem/:id`.
  int? lineIdOf(int productId) {
    for (final item in _cart?.cartItems ?? const <CartItemModel>[]) {
      if (item.model?.id == productId) return item.id;
    }
    return null;
  }

  /// Суммарное количество единиц — для бейджа и плашки. Читает `_cart`,
  /// поэтому корректно во всех состояниях, включая ошибку обновления.
  int get itemsCount {
    var total = 0;
    for (final item in _cart?.cartItems ?? const <CartItemModel>[]) {
      total += item.quantity;
    }
    return total;
  }

  int get linesCount => _cart?.cartItems?.length ?? 0;

  bool get hasItems => itemsCount > 0;

  void reset() {
    _epoch++;
    _cart = null;
    _changes = const [];
    _busyLines.clear();
    _busy = false;
    _loadedOnce = false;
    emit(const CartEmpty());
  }

  @override
  Future<void> close() {
    _events.close();
    return super.close();
  }

  // ── загрузка ──────────────────────────────────────────────────────────────

  /// Один запрос на всех: страница корзины, деталь товара, профиль и витрина
  /// магазина дёргают это одновременно.
  Future<void> getCart() {
    final inFlight = _inFlightGet;
    if (inFlight != null) return inFlight;
    final future = _fetch();
    _inFlightGet = future;
    return future.whenComplete(() => _inFlightGet = null);
  }

  Future<void> _fetch() async {
    final epoch = _epoch;
    if (_cart == null && state is! CartEmpty) emit(CartLoading());
    final result = await _cartRepository.getCart();
    if (epoch != _epoch) {
      cartLog.warn('stale GET dropped', 'epoch $epoch != $_epoch');
      return;
    }
    _applyFetch(result);
  }

  void _applyFetch(CartFetch result) {
    switch (result) {
      case CartFetchOk(:final cart, :final changes):
        _cart = cart;
        _changes = changes;
        if ((cart.cartItems ?? const []).isEmpty) {
          _cart = null;
          emit(const CartEmpty());
        } else {
          _emitCart();
        }
        if (changes.isNotEmpty) _events.add(CartChangesEvent(changes));
      case CartFetchNoCart():
      case CartFetchUnauthorized():
        // Гость и «корзины нет» выглядят одинаково: пустой экран, без ошибки.
        _cart = null;
        _changes = const [];
        emit(const CartEmpty());
      case CartFetchFailed():
        // Кэш есть — оставляем его и сообщаем о неудачном обновлении.
        if (_cart == null) {
          emit(CartGetError());
        } else {
          _emitCart();
          _events.add(const CartRefreshFailedEvent());
        }
    }
  }

  /// Разовая загрузка при старте, после логина и т.п. Гостю запрос не шлём:
  /// `appDio` всё равно отклонит его синтетическим 401.
  Future<void> ensureLoaded() async {
    if (_loadedOnce) return;
    _loadedOnce = true;
    if (await getAuthToken() == null) {
      emit(const CartEmpty());
      return;
    }
    await getCart();
  }

  /// После оформления заказа корзина на сервере удалена — гасим локально сразу,
  /// чтобы плашка и бейдж исчезли не дожидаясь запроса.
  Future<void> refreshAfterOrder() async {
    _epoch++;
    _cart = null;
    _changes = const [];
    emit(const CartEmpty());
    await getCart();
  }

  // ── мутации ───────────────────────────────────────────────────────────────

  Future<bool> addCart({required int id, ProductModel? product}) async {
    _epoch++;
    final epoch = _epoch;

    // Оптимистично, если знаем товар. Если не знаем — просто ждём ответ.
    if (product != null || quantityOf(id) > 0) {
      _applyOptimisticAdd(id, product);
      _emitCart(busy: true);
    } else {
      cartLog.warn('no optimistic add, product missing', 'id=$id');
      _setBusy(true);
    }

    final result = await _serialize(
      () => _cartRepository.addToCart(modelId: id, quantity: 1),
    );
    if (epoch != _epoch) return false;

    switch (result) {
      case CartWriteOk(:final cart, :final changes):
        if (cart != null) {
          // Цитируем сервер: здесь приходят настоящие id позиций.
          _cart = cart;
          _changes = changes;
          _emitCart();
          if (changes.isNotEmpty) _events.add(CartChangesEvent(changes));
        } else {
          await _refresh(epoch);
        }
        return true;
      case CartWriteNoCart():
        _cart = null;
        emit(const CartEmpty());
        return true;
      case CartWriteUnauthorized():
        await _refresh(epoch);
        _events.add(CartAddUnauthenticatedEvent(id));
        return false;
      case CartWriteRejected(:final message, :final statusCode):
        // Откатываем предсказание и подтягиваем правду с сервера.
        await _refresh(epoch);
        _events.add(CartWriteRejectedEvent(message, statusCode));
        return false;
      case CartWriteFailed():
        await _refresh(epoch);
        _events.add(const CartAddFailedEvent());
        return false;
    }
  }

  /// Уменьшить на единицу.
  ///
  /// Отдельной ручки для этого нет, а `quantity: -1` и `0` отбиваются
  /// валидацией. Поэтому: позицию удаляем и, если остаток больше нуля,
  /// добавляем заново с нужным количеством.
  ///
  /// Риск назван прямо: если удаление прошло, а повторное добавление упало
  /// (сеть или товар кончился между вызовами) — позиция теряется целиком.
  /// Серверной альтернативы нет; смягчаем одним повтором и явным сообщением.
  Future<void> removeCart({required int id}) async {
    var quantity = quantityOf(id);
    if (quantity <= 0) return;

    var lineId = lineIdOf(id);
    // id позиции 0 бывает у оптимистично добавленного товара — сначала
    // выясняем настоящий.
    if (lineId == null || lineId == 0) {
      await getCart();
      quantity = quantityOf(id);
      lineId = lineIdOf(id);
      if (quantity <= 0) return;
      if (lineId == null || lineId == 0) {
        _events.add(const CartRemoveFailedEvent());
        return;
      }
    }

    _epoch++;
    final epoch = _epoch;
    final line = lineId;
    final target = quantity - 1;

    _busyLines.add(line);
    _emitCart(busy: true);

    final result = await _serialize(() async {
      final deleted = await _cartRepository.deleteCartItem(cartItemId: line);
      if (deleted is! CartWriteOk && deleted is! CartWriteNoCart) {
        return deleted;
      }
      if (target <= 0) return deleted;

      var readded = await _cartRepository.addToCart(
        modelId: id,
        quantity: target,
      );
      if (readded is! CartWriteOk) {
        // Один повтор: обрыв сети между двумя запросами стоит пользователю
        // всей позиции, поэтому пробуем ещё раз.
        readded = await _cartRepository.addToCart(
          modelId: id,
          quantity: target,
        );
      }
      return readded;
    });

    _busyLines.remove(line);
    if (epoch != _epoch) return;

    switch (result) {
      case CartWriteOk(:final cart, :final changes):
        if (cart != null) {
          _cart = cart;
          _changes = changes;
          _emitCart();
        } else {
          await _refresh(epoch);
        }
      case CartWriteNoCart():
        _cart = null;
        emit(const CartEmpty());
      case CartWriteUnauthorized():
        await _refresh(epoch);
      case CartWriteRejected(:final message, :final statusCode):
        await _refresh(epoch);
        _events.add(CartWriteRejectedEvent(message, statusCode));
        if (target > 0) _events.add(const CartQuantityChangeFailedEvent());
      case CartWriteFailed():
        await _refresh(epoch);
        _events.add(
          target > 0
              ? const CartQuantityChangeFailedEvent()
              : const CartRemoveFailedEvent(),
        );
    }
  }

  /// Удалить позицию целиком (иконка корзины на карточке товара в корзине).
  Future<void> removeLine({required int id}) async {
    var lineId = lineIdOf(id);
    if (lineId == null || lineId == 0) {
      await getCart();
      lineId = lineIdOf(id);
      if (lineId == null || lineId == 0) {
        _events.add(const CartRemoveFailedEvent());
        return;
      }
    }

    _epoch++;
    final epoch = _epoch;
    final line = lineId;

    _busyLines.add(line);
    _emitCart(busy: true);

    final result = await _serialize(
      () => _cartRepository.deleteCartItem(cartItemId: line),
    );

    _busyLines.remove(line);
    if (epoch != _epoch) return;

    switch (result) {
      case CartWriteOk(:final cart):
        if (cart != null) {
          _cart = cart;
          _emitCart();
        } else {
          await _refresh(epoch);
        }
      case CartWriteNoCart():
        _cart = null;
        emit(const CartEmpty());
      case CartWriteUnauthorized():
      case CartWriteRejected():
      case CartWriteFailed():
        await _refresh(epoch);
        _events.add(const CartRemoveFailedEvent());
    }
  }

  /// Очистить корзину целиком — один `DELETE /cart`.
  ///
  /// Возвращает `true`, если на сервере корзины больше нет. UI должен дождаться
  /// результата и держать кнопку заблокированной: раньше очистка была
  /// «мгновенной» локально, а на сервере не делала ничего.
  Future<bool> clearCart() async {
    _epoch++;
    final epoch = _epoch;

    // Товары остаются на экране до подтверждения сервера.
    _emitCart(busy: true);

    final result = await _serialize(() => _cartRepository.clearCart());
    if (epoch != _epoch) return false;

    switch (result) {
      case CartWriteNoCart():
      case CartWriteUnauthorized():
        _cart = null;
        _changes = const [];
        _busy = false;
        emit(const CartEmpty());
        return true;
      case CartWriteOk():
      case CartWriteRejected():
      case CartWriteFailed():
        await _refresh(epoch);
        _events.add(const CartClearFailedEvent());
        return false;
    }
  }

  /// Перед оформлением заказа перечитываем корзину и возвращаем её вызывающему.
  ///
  /// Возврат значения вместо навигации через состояние: `CartPage` смонтирована
  /// сразу в двух местах (таб и шит поверх эфира), и раньше приходилось гадать,
  /// какой из инстансов должен уводить на оформление.
  Future<CartModel?> prepareCheckout() async {
    final epoch = _epoch;
    final result = await _cartRepository.getCart();
    if (epoch != _epoch) return null;

    switch (result) {
      case CartFetchOk(:final cart, :final changes):
        final items = cart.cartItems ?? const <CartItemModel>[];
        if (items.isEmpty) {
          _cart = null;
          emit(const CartEmpty());
          _events.add(const CartEmptyOnCheckoutEvent());
          return null;
        }
        _cart = cart;
        _changes = changes;
        _emitCart();
        if (changes.isNotEmpty) _events.add(CartChangesEvent(changes));
        return cart;
      case CartFetchNoCart():
      case CartFetchUnauthorized():
        _cart = null;
        emit(const CartEmpty());
        _events.add(const CartEmptyOnCheckoutEvent());
        return null;
      case CartFetchFailed():
        // Кэш не трогаем — иначе экран опустеет при живой корзине.
        _events.add(const CartRefreshFailedEvent());
        return null;
    }
  }

  // ── внутреннее ────────────────────────────────────────────────────────────

  Future<T> _serialize<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _chain = _chain.then((_) async {
      try {
        completer.complete(await action());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  Future<void> _refresh(int epoch) async {
    final result = await _cartRepository.getCart();
    if (epoch != _epoch) return;
    _applyFetch(result);
  }

  void _setBusy(bool value) {
    _busy = value;
    _emitCartRaw();
  }

  void _emitCart({bool busy = false}) {
    _busy = busy;
    _emitCartRaw();
  }

  void _emitCartRaw() {
    final cart = _cart;
    if (cart == null || (cart.cartItems ?? const []).isEmpty) {
      emit(const CartEmpty());
      return;
    }
    emit(
      CartGot(
        cart: cart,
        changes: _changes,
        busy: _busy,
        busyLines: Set.unmodifiable(_busyLines),
      ),
    );
  }

  /// Оптимистичное «+1». Применяется только к добавлению — см. док к классу.
  void _applyOptimisticAdd(int productId, ProductModel? product) {
    final items = List<CartItemModel>.from(_cart?.cartItems ?? const []);
    final idx = items.indexWhere((i) => i.model?.id == productId);
    if (idx >= 0) {
      items[idx].quantity += 1;
    } else {
      if (product == null) return;
      items.add(
        CartItemModel(
          id: 0,
          quantity: 1,
          totalPrice: product.price ?? 0,
          model: product,
        ),
      );
    }
    var total = 0;
    for (final i in items) {
      total += (i.model?.price ?? 0) * i.quantity;
    }
    _cart = CartModel(
      id: _cart?.id ?? 0,
      userId: _cart?.userId ?? 0,
      totalPrice: total,
      oldTotalPrice: _cart?.oldTotalPrice,
      cartItems: items,
      deliveryInfo: _cart?.deliveryInfo,
    );
  }
}
