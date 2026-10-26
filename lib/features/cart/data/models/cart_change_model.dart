/// Элемент массива `changes` из `GET /cart`.
///
/// `GET /cart` синхронизирует корзину с каталогом: позиции с закончившимся
/// товаром удаляются, цены переписываются на актуальные. `changes` — готовые
/// данные для сообщений «товар подорожал» / «товар закончился».
///
/// Парсер намеренно написан руками и терпим к именам ключей: в документации
/// массив описан прозой, без точной схемы. Сырой ответ логируется в
/// `CartServices`, чтобы имена можно было уточнить по стенду и ужесточить
/// разбор позже.
enum CartChangeKind { removed, quantityReduced, priceChanged, unknown }

class CartChangeModel {
  const CartChangeModel({
    this.name,
    this.oldQuantity,
    this.newQuantity,
    this.oldPrice,
    this.newPrice,
  });

  final String? name;
  final int? oldQuantity;
  final int? newQuantity;
  final int? oldPrice;
  final int? newPrice;

  CartChangeKind get kind {
    if (newQuantity != null && newQuantity == 0) return CartChangeKind.removed;
    if (newQuantity != null &&
        oldQuantity != null &&
        newQuantity! < oldQuantity!) {
      return CartChangeKind.quantityReduced;
    }
    if (newPrice != null && oldPrice != null && newPrice != oldPrice) {
      return CartChangeKind.priceChanged;
    }
    return CartChangeKind.unknown;
  }

  factory CartChangeModel.fromJson(Map<String, dynamic> json) {
    return CartChangeModel(
      name: _firstString(json, const [
        'name',
        'modelName',
        'productName',
        'title',
      ]) ??
          _nestedModelName(json),
      oldQuantity: _firstInt(json, const [
        'oldQuantity',
        'quantityOld',
        'previousQuantity',
        'quantityBefore',
      ]),
      newQuantity: _firstInt(json, const [
        'newQuantity',
        'quantityNew',
        'quantity',
        'quantityAfter',
      ]),
      oldPrice: _firstInt(json, const [
        'oldPrice',
        'priceOld',
        'previousPrice',
        'priceBefore',
      ]),
      newPrice: _firstInt(json, const [
        'newPrice',
        'priceNew',
        'price',
        'priceAfter',
      ]),
    );
  }

  static String? _nestedModelName(Map<String, dynamic> json) {
    final model = json['model'];
    if (model is Map && model['name'] is String) return model['name'] as String;
    return null;
  }

  static String? _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v is String && v.trim().isNotEmpty) return v;
    }
    return null;
  }

  static int? _firstInt(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) {
        final parsed = int.tryParse(v);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }
}
