import 'package:json_annotation/json_annotation.dart';

import 'review_model.dart';

part 'reviews_page_response.g.dart';

/// Ответ `GET /model/:id/reviews?limit=&skip=`.
///
/// [total] — количество **видимых** отзывов: админ может скрыть отзыв, не
/// удаляя, и тогда он выпадает и из списка, и из счётчика.
@JsonSerializable(explicitToJson: true)
class ReviewsPageResponse {
  @JsonKey(defaultValue: 0)
  final int total;

  @JsonKey(defaultValue: <ReviewModel>[])
  final List<ReviewModel> items;

  const ReviewsPageResponse({required this.total, required this.items});

  factory ReviewsPageResponse.fromJson(Map<String, dynamic> json) =>
      _$ReviewsPageResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewsPageResponseToJson(this);
}
