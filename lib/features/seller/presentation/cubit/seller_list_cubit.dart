import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/seller_services.dart';
import '../../data/models/seller_model.dart';
import '../../domain/repositories/seller_repository.dart';

part 'seller_list_state.dart';

/// Вкладка «Все магазины» — `GET /seller`.
class SellerListCubit extends Cubit<SellerListState> {
  SellerListCubit({SellerRepository? repository})
      : _repository = repository ?? SellerServices(),
        super(const SellerListState());

  final SellerRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: SellerListStatus.loading));
    try {
      final all = await _repository.getSellers();
      if (all.isEmpty) {
        // Пустой список от `getSellers()` неотличим от ошибки: датасорс по
        // конвенции проекта глотает исключения в `const []`. Показываем
        // пустое состояние — оно и для реально пустого списка корректно.
        emit(state.copyWith(status: SellerListStatus.loaded, sellers: const []));
        return;
      }
      emit(
        state.copyWith(
          status: SellerListStatus.loaded,
          sellers: visibleShops(all),
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: SellerListStatus.error));
    }
  }

  /// Правила из контракта, вынесены статиком ради тестируемости:
  /// * `isOwn: true` — это сам Bai Market, его вкладка «Весь каталог» и так
  ///   показывает; на «Все магазины» он не нужен;
  /// * сортировка по `firstName` по возрастанию.
  ///
  /// В Dart нет коллатора, поэтому кириллица и казахские буквы сортируются по
  /// кодовым единицам. Для «по возрастанию» этого достаточно, и результат
  /// одинаков во всех локалях.
  static List<SellerModel> visibleShops(List<SellerModel> all) {
    final shops = all.where((s) => s.isOwn != true).toList();
    shops.sort(
      (a, b) => (a.firstName ?? '')
          .toLowerCase()
          .compareTo((b.firstName ?? '').toLowerCase()),
    );
    return shops;
  }
}
