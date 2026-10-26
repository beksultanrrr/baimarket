import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../catalog/data/models/category_product_model.dart';
import '../../data/datasources/seller_services.dart';
import '../../data/models/seller_model.dart';
import '../../domain/repositories/seller_repository.dart';

part 'seller_store_state.dart';

/// Витрина одного магазина: `GET /seller/:id/models` с сортировкой и
/// постраничной догрузкой.
class SellerStoreCubit extends Cubit<SellerStoreState> {
  SellerStoreCubit({SellerRepository? repository})
      : _repository = repository ?? SellerServices(),
        super(const SellerStoreState());

  final SellerRepository _repository;

  static const pageSize = 20;

  /// Первая страница. Параллельно, если имя магазина не передали через
  /// `extra`, тянем `GET /seller` и находим продавца там: ручка товаров
  /// объекта продавца не возвращает, а отдельной `GET /seller/:id` у бэка нет.
  Future<void> load({
    required int id,
    String sort = 'popular',
    bool needSeller = true,
  }) async {
    emit(state.copyWith(status: SellerStoreStatus.loading, sort: sort));
    try {
      final results = await Future.wait([
        _repository.getSellerProducts(id: id, sort: sort, limit: pageSize),
        if (needSeller) _repository.getSellers(),
      ]);

      final products = results.first as SellerProductsResult;
      final seller = needSeller
          ? _findSeller(results.last as List<SellerModel>, id)
          : state.seller;

      switch (products) {
        case SellerProductsNotFound():
          emit(state.copyWith(status: SellerStoreStatus.notFound));
        case SellerProductsFailed():
          emit(state.copyWith(status: SellerStoreStatus.error));
        case SellerProductsLoaded(:final data):
          emit(
            state.copyWith(
              status: SellerStoreStatus.loaded,
              models: data.models,
              total: data.total,
              sort: sort,
              seller: seller,
            ),
          );
      }
    } catch (_) {
      emit(state.copyWith(status: SellerStoreStatus.error));
    }
  }

  /// Догрузка следующей страницы. Приписывает к уже показанному списку.
  Future<void> loadMore({required int id}) async {
    if (state.status == SellerStoreStatus.loading ||
        state.status == SellerStoreStatus.loadingMore ||
        state.status == SellerStoreStatus.sorting ||
        !state.hasMore) {
      return;
    }
    final sortAtStart = state.sort;
    final skip = state.models.length;
    emit(state.copyWith(status: SellerStoreStatus.loadingMore));
    try {
      final result = await _repository.getSellerProducts(
        id: id,
        sort: sortAtStart,
        limit: pageSize,
        skip: skip,
      );
      // Пока летел запрос, пользователь мог сменить сортировку — тогда ответ
      // относится к другому списку и его надо выбросить.
      if (sortAtStart != state.sort) return;

      switch (result) {
        case SellerProductsLoaded(:final data):
          emit(
            state.copyWith(
              status: SellerStoreStatus.loaded,
              models: [...state.models, ...data.models],
              total: data.total,
            ),
          );
        case SellerProductsNotFound():
        case SellerProductsFailed():
          // Первая страница уже показана — не роняем экран, просто
          // возвращаемся в loaded, следующий скролл попробует снова.
          emit(state.copyWith(status: SellerStoreStatus.loaded));
      }
    } catch (_) {
      emit(state.copyWith(status: SellerStoreStatus.loaded));
    }
  }

  Future<void> changeSort({required int id, required String sort}) async {
    if (sort == state.sort) return;
    emit(state.copyWith(status: SellerStoreStatus.sorting, sort: sort));
    try {
      final result = await _repository.getSellerProducts(
        id: id,
        sort: sort,
        limit: pageSize,
      );
      switch (result) {
        case SellerProductsLoaded(:final data):
          emit(
            state.copyWith(
              status: SellerStoreStatus.loaded,
              models: data.models,
              total: data.total,
              sort: sort,
            ),
          );
        case SellerProductsNotFound():
          emit(state.copyWith(status: SellerStoreStatus.notFound));
        case SellerProductsFailed():
          emit(state.copyWith(status: SellerStoreStatus.error));
      }
    } catch (_) {
      emit(state.copyWith(status: SellerStoreStatus.error));
    }
  }

  Future<void> refresh({required int id}) =>
      load(id: id, sort: state.sort, needSeller: state.seller == null);

  static SellerModel? _findSeller(List<SellerModel> all, int id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }
}
