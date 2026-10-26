part of 'seller_store_cubit.dart';

enum SellerStoreStatus {
  initial,
  loading,
  sorting,
  loadingMore,
  loaded,
  notFound,
  error,
}

class SellerStoreState extends Equatable {
  const SellerStoreState({
    this.status = SellerStoreStatus.initial,
    this.models = const [],
    this.total = 0,
    this.sort = 'popular',
    this.seller,
  });

  final SellerStoreStatus status;
  final List<CategoryProductModel> models;

  /// Общее число товаров магазина — идёт в строку «67 товаров».
  /// Это НЕ длина [models]: та растёт по мере догрузки страниц.
  final int total;

  final String sort;
  final SellerModel? seller;

  bool get hasMore => models.length < total;

  /// [models] и [seller] всегда заменяются целиком, поэтому обычный
  /// `models ?? this.models` здесь корректен: при догрузке кубит передаёт уже
  /// склеенный список.
  SellerStoreState copyWith({
    SellerStoreStatus? status,
    List<CategoryProductModel>? models,
    int? total,
    String? sort,
    SellerModel? seller,
  }) {
    return SellerStoreState(
      status: status ?? this.status,
      models: models ?? this.models,
      total: total ?? this.total,
      sort: sort ?? this.sort,
      seller: seller ?? this.seller,
    );
  }

  @override
  List<Object?> get props => [status, models, total, sort, seller];
}
