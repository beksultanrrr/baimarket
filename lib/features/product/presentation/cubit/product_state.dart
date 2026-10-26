part of 'product_cubit.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object> get props => [];
}

class ProductInitial extends ProductState {}

class ProductGetting extends ProductState {}

class ProductGot extends ProductState {
  final ProductModel productModel;
  const ProductGot({required this.productModel});

  /// Без этого `props` наследуется пустым, и Cubit схлопывает два подряд
  /// идущих `ProductGot` — перезапрос товара (после отзыва, ретрая, смены
  /// избранного) не вызывал перерисовку.
  ///
  /// `ProductModel` намеренно не Equatable: сравнение по идентичности — то, что
  /// нужно, каждый свежий `fromJson` даёт новый объект.
  @override
  List<Object> get props => [productModel];
}

/// Товар мягко удалён — `GET /model/:id` вернул 404. Отдельно от
/// [ProductGetError], потому что пользователю надо показать «товар больше не
/// доступен», а не «ошибка, попробуйте снова».
class ProductNotFound extends ProductState {}

class ProductGetError extends ProductState {}
