import '../../data/models/review_model.dart';
import '../../data/models/reviews_page_response.dart';

/// Результат `POST /model/:id/reviews`.
///
/// Отдельные ветки нужны потому, что 409 и 429 требуют разных сообщений:
/// один отзыв на товар от пользователя, и лимит 5 запросов в минуту.
sealed class CreateReviewResult {
  const CreateReviewResult();
}

class CreateReviewSuccess extends CreateReviewResult {
  const CreateReviewSuccess(this.review);
  final ReviewModel? review;
}

/// 409 — отзыв на этот товар уже оставлен. Менять его надо через
/// `PATCH /reviews/:id`, но своего отзыва в списке не найти (см. ниже).
class CreateReviewAlreadyExists extends CreateReviewResult {
  const CreateReviewAlreadyExists();
}

/// 429 — сработал антиспам (5 запросов в минуту).
class CreateReviewRateLimited extends CreateReviewResult {
  const CreateReviewRateLimited();
}

/// 404 — товара нет или он удалён.
class CreateReviewProductMissing extends CreateReviewResult {
  const CreateReviewProductMissing();
}

class CreateReviewUnauthorized extends CreateReviewResult {
  const CreateReviewUnauthorized();
}

class CreateReviewFailed extends CreateReviewResult {
  const CreateReviewFailed();
}

/// Отзывы о товаре.
///
/// `PATCH`/`DELETE /reviews/:id` намеренно не объявлены: элементы
/// `GET /model/:id/reviews` не содержат ни `isOwn`, ни `userId`, поэтому
/// определить, какой отзыв принадлежит текущему пользователю, невозможно —
/// значит, кнопку «изменить» негде отрисовать. Нужен `isOwn` на элементах
/// списка либо ручка `GET /reviews/my?modelId=` со стороны бэка.
abstract class ReviewsRepository {
  Future<ReviewsPageResponse?> getReviews({
    required int modelId,
    int limit,
    int skip,
  });

  Future<CreateReviewResult> createReview({
    required int modelId,
    required String text,
    int? rating,
  });
}
