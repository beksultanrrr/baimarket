import 'package:bai_market/features/product/data/models/product_model.dart';

/// Результат `GET /model/:id`.
///
/// `null` тут больше не годится: удаление товара стало мягким, и на удалённый
/// товар ручка отдаёт **404**. Это надо показать как «товар больше не доступен»,
/// а не как ошибку сети — карточка может быть открыта по ссылке или из истории.
sealed class ProductDetailResult {
  const ProductDetailResult();
}

class ProductDetailLoaded extends ProductDetailResult {
  const ProductDetailLoaded(this.product);
  final ProductModel product;
}

class ProductDetailNotFound extends ProductDetailResult {
  const ProductDetailNotFound();
}

class ProductDetailFailed extends ProductDetailResult {
  const ProductDetailFailed();
}

abstract class ProductRepository {
  Future<ProductDetailResult> getProductDetail({required int id});
}
