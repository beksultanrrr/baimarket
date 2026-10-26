part of 'cart_cubit.dart';

sealed class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

/// Корзины нет.
///
/// Отдельного состояния «пустая корзина» в контракте не существует: позиция
/// корзины и позиция заказа — одна строка, при оформлении она уезжает в заказ,
/// а корзина удаляется целиком. `GET /cart` в этом случае отдаёт 404, и это
/// нормальное состояние, а не ошибка.
class CartEmpty extends CartState {
  const CartEmpty();
}

class CartGot extends CartState {
  CartGot({
    required this.cart,
    this.changes = const [],
    this.busy = false,
    this.busyLines = const {},
  })  : _signature = _snapshot(cart, busy, busyLines, changes.length),
        itemsCount = _countItems(cart),
        linesCount = cart.cartItems?.length ?? 0;

  final CartModel cart;

  /// Что изменил сервер при синхронизации с каталогом.
  final List<CartChangeModel> changes;

  /// Летит запрос, меняющий корзину целиком (очистка, добавление).
  final bool busy;

  /// id позиций (`cartItems[].id`) с летящим запросом.
  final Set<int> busyLines;

  final int itemsCount;
  final int linesCount;

  final String _signature;

  /// Подпись обязана включать **id позиции**: оптимистично добавленный товар
  /// имеет `id: 0`, а после ответа сервера тот же товар в том же количестве
  /// приходит с настоящим id. Без него подписи совпадают, Cubit схлопывает
  /// эмиты, и в UI остаётся `id: 0` — а именно он идёт в `DELETE /cartitem/:id`.
  static String _snapshot(
    CartModel cart,
    bool busy,
    Set<int> busyLines,
    int changesCount,
  ) {
    final items = cart.cartItems ?? const <CartItemModel>[];
    final parts = items
        .map((i) => '${i.id}:${i.model?.id}:${i.quantity}:${i.unitPrice}')
        .join(',');
    return '${cart.id}|${cart.totalPrice}|${cart.oldTotalPrice}|'
        '${items.length}|$parts|$busy|${busyLines.length}|$changesCount';
  }

  static int _countItems(CartModel cart) {
    var total = 0;
    for (final i in cart.cartItems ?? const <CartItemModel>[]) {
      total += i.quantity;
    }
    return total;
  }

  @override
  List<Object?> get props => [_signature];
}

class CartGetError extends CartState {}
