import 'package:bai_market/features/cart/data/models/cart_item_model.dart';
import 'package:bai_market/features/cart/data/models/cart_model.dart';
import 'package:bai_market/features/cart/domain/repositories/cart_repository.dart';
import 'package:bai_market/features/product/data/models/product_model.dart';

ProductModel product(int id, {int price = 1000}) => ProductModel(
      id: id,
      name: 'Товар $id',
      price: price,
      oldPrice: null,
      deal: null,
      photoUrls: null,
      descriptionKz: null,
      descriptionRu: null,
      descriptionEn: null,
      detailedDescriptionKz: null,
      detailedDescriptionRu: null,
      detailedDescriptionEn: null,
      inStockCount: 10,
      weightInKg: null,
      collections: null,
      product: null,
      isInFavorite: false,
    );

/// Сервер держит корзину как map «modelId → количество» и раздаёт позициям
/// нарастающие id — так же, как настоящий бэк.
class FakeCartRepository implements CartRepository {
  FakeCartRepository();

  final Map<int, int> _quantities = {};
  final Map<int, int> _lineIds = {};
  int _nextLineId = 1;
  int _cartId = 1;
  bool _cartExists = false;

  /// Журнал вызовов для проверок в тестах.
  final List<String> calls = [];

  /// Искусственная задержка ответа `getCart` — нужна для проверки epoch-гарда.
  Future<void> Function()? getCartDelay;

  /// Заставить следующий `addToCart` вернуть отказ сервера.
  String? rejectNextAddWith;

  /// Заставить следующий `addToCart` упасть (используется для проверки потери
  /// позиции при неатомарном уменьшении).
  int failNextAdds = 0;

  void seed(Map<int, int> quantities) {
    _quantities
      ..clear()
      ..addAll(quantities);
    _lineIds.clear();
    for (final id in quantities.keys) {
      _lineIds[id] = _nextLineId++;
    }
    _cartExists = quantities.isNotEmpty;
  }

  Map<int, int> get serverQuantities => Map.unmodifiable(_quantities);

  CartModel _buildCart() => CartModel(
        id: _cartId,
        userId: 1,
        totalPrice: _quantities.values
            .fold<int>(0, (sum, qty) => sum + qty * 1000),
        oldTotalPrice: null,
        deliveryInfo: null,
        cartItems: _quantities.entries
            .map(
              (e) => CartItemModel(
                id: _lineIds[e.key]!,
                quantity: e.value,
                totalPrice: e.value * 1000,
                unitPrice: 1000,
                model: product(e.key),
              ),
            )
            .toList(),
      );

  @override
  Future<CartFetch> getCart() async {
    calls.add('getCart');
    final delay = getCartDelay;
    if (delay != null) await delay();
    if (!_cartExists || _quantities.isEmpty) return const CartFetchNoCart();
    return CartFetchOk(_buildCart(), const []);
  }

  @override
  Future<CartWrite> addToCart({required int modelId, int quantity = 1}) async {
    calls.add('addToCart($modelId,$quantity)');
    if (quantity < 1) {
      throw StateError('quantity < 1 must never reach the server');
    }
    if (failNextAdds > 0) {
      failNextAdds--;
      return const CartWriteFailed();
    }
    final reject = rejectNextAddWith;
    if (reject != null) {
      rejectNextAddWith = null;
      return CartWriteRejected(reject, 400);
    }
    if (!_cartExists) {
      _cartExists = true;
      _cartId++;
    }
    _quantities[modelId] = (_quantities[modelId] ?? 0) + quantity;
    _lineIds.putIfAbsent(modelId, () => _nextLineId++);
    return CartWriteOk(_buildCart(), const []);
  }

  @override
  Future<CartWrite> deleteCartItem({required int cartItemId}) async {
    calls.add('deleteCartItem($cartItemId)');
    final modelId = _lineIds.entries
        .where((e) => e.value == cartItemId)
        .map((e) => e.key)
        .firstOrNull;
    if (modelId == null) return const CartWriteOk(null, []);
    _quantities.remove(modelId);
    _lineIds.remove(modelId);
    if (_quantities.isEmpty) {
      _cartExists = false;
      return const CartWriteNoCart();
    }
    return CartWriteOk(_buildCart(), const []);
  }

  @override
  Future<CartWrite> clearCart() async {
    calls.add('clearCart');
    _quantities.clear();
    _lineIds.clear();
    _cartExists = false;
    return const CartWriteNoCart();
  }
}
