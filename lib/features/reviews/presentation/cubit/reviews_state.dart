part of 'reviews_cubit.dart';

enum ReviewsStatus { initial, loading, loadingMore, loaded, error }

class ReviewsState extends Equatable {
  const ReviewsState({
    this.status = ReviewsStatus.initial,
    this.items = const [],
    this.total = 0,
    this.submitting = false,
  });

  final ReviewsStatus status;
  final List<ReviewModel> items;

  /// Общее число видимых отзывов у товара — не длина [items], та растёт по
  /// мере догрузки страниц.
  final int total;

  final bool submitting;

  bool get hasMore => items.length < total;

  ReviewsState copyWith({
    ReviewsStatus? status,
    List<ReviewModel>? items,
    int? total,
    bool? submitting,
  }) {
    return ReviewsState(
      status: status ?? this.status,
      items: items ?? this.items,
      total: total ?? this.total,
      submitting: submitting ?? this.submitting,
    );
  }

  @override
  List<Object?> get props => [status, items, total, submitting];
}
