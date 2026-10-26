import '../../data/models/cart_change_model.dart';
import '../../data/models/cart_model.dart';

/// Результат чтения корзины.
///
/// «Пустой корзины» в контракте не существует — есть «корзины нет»: позиция
/// корзины и позиция заказа это одна строка, при оформлении она переезжает в
/// заказ, а корзина удаляется целиком. Поэтому 404 у `GET /cart` — нормальное
/// состояние ([CartFetchNoCart]), а не ошибка.
sealed class CartFetch {
  const CartFetch();
}

class CartFetchOk extends CartFetch {
  const CartFetchOk(this.cart, this.changes);
  final CartModel cart;

  /// Непустой список — товар закончился или изменилась цена. Стоит показать.
  final List<CartChangeModel> changes;
}

/// `GET /cart` → 404. Корзины нет: после очистки и после оформления заказа.
class CartFetchNoCart extends CartFetch {
  const CartFetchNoCart();
}

class CartFetchUnauthorized extends CartFetch {
  const CartFetchUnauthorized();
}

class CartFetchFailed extends CartFetch {
  const CartFetchFailed(this.message);
  final String? message;
}

/// Результат изменения корзины.
sealed class CartWrite {
  const CartWrite();
}

class CartWriteOk extends CartWrite {
  const CartWriteOk(this.cart, this.changes);

  /// `null` — ответ не содержал корзины, вызывающему нужно перечитать её сам.
  final CartModel? cart;
  final List<CartChangeModel> changes;
}

/// Корзины больше нет — успешный `DELETE /cart` (и 200, и 404: «уже пусто»).
class CartWriteNoCart extends CartWrite {
  const CartWriteNoCart();
}

class CartWriteUnauthorized extends CartWrite {
  const CartWriteUnauthorized();
}

/// Сервер отказал осмысленно: 400 «Not enough items in stock» при добавлении
/// сверх остатка, 404 «Model not found» для мягко удалённого товара.
class CartWriteRejected extends CartWrite {
  const CartWriteRejected(this.message, this.statusCode);
  final String message;
  final int? statusCode;
}

class CartWriteFailed extends CartWrite {
  const CartWriteFailed();
}

abstract class CartRepository {
  Future<CartFetch> getCart();

  /// `POST /cart` — [quantity] **прибавляется** к тому, что уже в корзине.
  /// Значения меньше 1 запрещены валидацией (400), поэтому уменьшить
  /// количество через эту ручку невозможно.
  Future<CartWrite> addToCart({required int modelId, int quantity});

  /// `DELETE /cartitem/:id`, где id — это `cartItems[].id` из ответа,
  /// **не** `modelId`.
  Future<CartWrite> deleteCartItem({required int cartItemId});

  /// `DELETE /cart` — удаляет корзину целиком.
  Future<CartWrite> clearCart();
}
