import '../../data/models/seller_model.dart';
import '../../data/models/seller_products_response.dart';

/// Результат `GET /seller/:id/models`.
///
/// Здесь нельзя обойтись `null`, как в остальных датасорсах: бэк отдаёт **404**,
/// если продавца нет или он удалён, и это надо показать отдельным экраном
/// «магазин больше не доступен», а не общей ошибкой сети. Карточка магазина
/// вполне может устареть между загрузкой списка и тапом по ней.
sealed class SellerProductsResult {
  const SellerProductsResult();
}

class SellerProductsLoaded extends SellerProductsResult {
  const SellerProductsLoaded(this.data);
  final SellerProductsResponse data;
}

class SellerProductsNotFound extends SellerProductsResult {
  const SellerProductsNotFound();
}

class SellerProductsFailed extends SellerProductsResult {
  const SellerProductsFailed();
}

abstract class SellerRepository {
  /// `GET /seller` — плоский список всех активных продавцов, включая сам
  /// Bai Market (`isOwn: true`). Фильтрация и сортировка на клиенте.
  Future<List<SellerModel>> getSellers();

  /// `GET /seller/:id/models?sort=&limit=&skip=`
  Future<SellerProductsResult> getSellerProducts({
    required int id,
    required String sort,
    int limit,
    int skip,
  });
}
