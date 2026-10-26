import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/shimmer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../reviews/presentation/cubit/reviews_cubit.dart';
import '../../../reviews/presentation/widgets/review_composer_sheet.dart';
import '../../../reviews/presentation/widgets/review_item.dart';
import '../../data/models/product_model.dart';
import '../../../live/presentation/widgets/live_shopping_scope.dart';

/// Превью-блок отзывов на детали товара: заголовок со счётчиком, три последних
/// отзыва и кнопка «Читать все».
///
/// Счётчик берём из `product.reviewsCount` (`GET /model/:id`) — он приходит
/// раньше самого списка, поэтому на первой отрисовке цифра уже правильная. Как
/// только список загрузился, переключаемся на `state.total`: после отправки
/// отзыва он свежее, а перезапрашивать товар ради одного числа не нужно.
class ProductReviewsSection extends StatelessWidget {
  const ProductReviewsSection({super.key, required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<ReviewsCubit, ReviewsState>(
      builder: (context, state) {
        final loaded = state.status == ReviewsStatus.loaded || state.status == ReviewsStatus.loadingMore;
        final count = loaded ? state.total : (product.reviewsCount ?? 0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(l10n.reviews, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black, fontFamily: 'Gilroy')),
                const Spacer(),
                Text(l10n.reviewsCount(count.toString()), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54, fontFamily: 'Gilroy')),
              ],
            ),
            const SizedBox(height: 16),

            if (!loaded && state.status != ReviewsStatus.error)
              const _PreviewSkeleton()
            else if (state.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  state.status == ReviewsStatus.error ? l10n.reviewsLoadError : l10n.reviewsEmpty,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54, fontFamily: 'Gilroy'),
                ),
              )
            else
              ...state.items.take(3).map((review) => ReviewItem(review: review, maxLines: 4)),

            const SizedBox(height: 16),

            // «Читать все» — только когда есть что читать сверх превью.
            // Иначе показываем призыв оставить отзыв.
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (count > 3) {
                    liveAwarePush(context, '/product/${product.id}/reviews',
                        extra: product);
                  } else {
                    showReviewComposerSheet(context: context, modelId: product.id, cubit: context.read<ReviewsCubit>());
                  }
                },
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(color: Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(10)),
                  child: Center(
                    child: Text(count > 3 ? l10n.readAll : l10n.orderLeaveReview, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87, fontFamily: 'Gilroy')),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PreviewSkeleton extends StatelessWidget {
  const _PreviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        SizedBox(height: 56, child: SimpleShimmer(borderRadius: 10)),
        SizedBox(height: 12),
        SizedBox(height: 56, child: SimpleShimmer(borderRadius: 10)),
        SizedBox(height: 12),
        SizedBox(height: 56, child: SimpleShimmer(borderRadius: 10)),
      ],
    );
  }
}
