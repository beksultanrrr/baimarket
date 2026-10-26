import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/reviews_services.dart';
import '../../data/models/review_model.dart';
import '../../domain/repositories/reviews_repository.dart';

part 'reviews_state.dart';

class ReviewsCubit extends Cubit<ReviewsState> {
  ReviewsCubit({ReviewsRepository? repository})
      : _repository = repository ?? ReviewsServices(),
        super(const ReviewsState());

  final ReviewsRepository _repository;

  int _pageSize = 10;

  Future<void> load({required int modelId, int limit = 10}) async {
    _pageSize = limit;
    emit(state.copyWith(status: ReviewsStatus.loading));
    final page = await _repository.getReviews(modelId: modelId, limit: limit);
    if (page == null) {
      emit(state.copyWith(status: ReviewsStatus.error));
      return;
    }
    emit(
      state.copyWith(
        status: ReviewsStatus.loaded,
        items: page.items,
        total: page.total,
      ),
    );
  }

  Future<void> loadMore({required int modelId}) async {
    if (state.status == ReviewsStatus.loading ||
        state.status == ReviewsStatus.loadingMore ||
        !state.hasMore) {
      return;
    }
    final skip = state.items.length;
    emit(state.copyWith(status: ReviewsStatus.loadingMore));
    final page = await _repository.getReviews(
      modelId: modelId,
      limit: _pageSize,
      skip: skip,
    );
    if (page == null) {
      // Первая страница уже показана — не роняем экран.
      emit(state.copyWith(status: ReviewsStatus.loaded));
      return;
    }
    emit(
      state.copyWith(
        status: ReviewsStatus.loaded,
        items: [...state.items, ...page.items],
        total: page.total,
      ),
    );
  }

  Future<void> refresh({required int modelId}) =>
      load(modelId: modelId, limit: _pageSize);

  /// Отправка отзыва. Возвращает результат, чтобы UI показал нужное сообщение
  /// и закрыл шит только при успехе.
  Future<CreateReviewResult> submit({
    required int modelId,
    required String text,
    int? rating,
  }) async {
    emit(state.copyWith(submitting: true));
    final result = await _repository.createReview(
      modelId: modelId,
      text: text,
      rating: rating,
    );
    emit(state.copyWith(submitting: false));
    if (result is CreateReviewSuccess) {
      await refresh(modelId: modelId);
    }
    return result;
  }
}
