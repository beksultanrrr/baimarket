import 'package:dio/dio.dart';

import '../../../../core/network/app_dio.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/urls.dart';
import '../../domain/repositories/reviews_repository.dart';
import '../models/review_model.dart';
import '../models/reviews_page_response.dart';

class ReviewsServices implements ReviewsRepository {
  @override
  Future<ReviewsPageResponse?> getReviews({
    required int modelId,
    int limit = 10,
    int skip = 0,
  }) async {
    try {
      // Список публичный: optionalAuthDio, чтобы работало и для гостей.
      final response = await optionalAuthDio.get(
        '${mainUrl}model/$modelId/reviews',
        queryParameters: {'limit': limit, 'skip': skip},
      );
      if (response.statusCode != 200 || response.data is! Map) {
        reviewsLog.warn(
          'getReviews unexpected response',
          'status=${response.statusCode}, data=${response.data.runtimeType}',
        );
        return null;
      }
      final page = ReviewsPageResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      reviewsLog.api(
        'getReviews model=$modelId skip=$skip',
        '→ ${page.items.length}/${page.total}',
      );
      return page;
    } catch (e, st) {
      reviewsLog.error('getReviews exception', e.toString(), e, st);
      return null;
    }
  }

  @override
  Future<CreateReviewResult> createReview({
    required int modelId,
    required String text,
    int? rating,
  }) async {
    try {
      // Создание требует JWT — здесь уместен appDio с его локальным 401.
      final response = await appDio.post(
        '${mainUrl}model/$modelId/reviews',
        data: {
          'text': text,
          if (rating != null) 'rating': rating,
        },
      );
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        reviewsLog.api('createReview model=$modelId', 'status=$code');
        final data = response.data;
        return CreateReviewSuccess(
          data is Map
              ? ReviewModel.fromJson(Map<String, dynamic>.from(data))
              : null,
        );
      }
      reviewsLog.warn('createReview unexpected status', 'status=$code');
      return const CreateReviewFailed();
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      reviewsLog.warn('createReview failed', 'status=$code');
      switch (code) {
        case 409:
          return const CreateReviewAlreadyExists();
        case 429:
          return const CreateReviewRateLimited();
        case 404:
          return const CreateReviewProductMissing();
        case 401:
          return const CreateReviewUnauthorized();
        default:
          return const CreateReviewFailed();
      }
    } catch (e, st) {
      reviewsLog.error('createReview exception', e.toString(), e, st);
      return const CreateReviewFailed();
    }
  }
}
