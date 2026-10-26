import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_pallete.dart';
import '../../../../core/urls.dart';
import '../../../../core/utils/translation_utils.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../core/widgets/load_more_listener.dart';
import '../../../../core/widgets/show_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../reviews/presentation/cubit/reviews_cubit.dart';
import '../../../reviews/presentation/widgets/review_composer_sheet.dart';
import '../../../reviews/presentation/widgets/review_item.dart';
import '../../data/models/product_model.dart';

/// Экран «Читать все» — весь список отзывов с постраничной догрузкой.
///
/// Свой `ReviewsCubit`, отдельный от превью-блока на детали товара: у экранов
/// разный размер страницы и независимый скролл.
class ProductReviewsPage extends StatefulWidget {
  const ProductReviewsPage({super.key, required this.product});
  final ProductModel product;

  @override
  State<ProductReviewsPage> createState() => _ProductReviewsPageState();
}

class _ProductReviewsPageState extends State<ProductReviewsPage> {
  final ReviewsCubit _cubit = ReviewsCubit();

  @override
  void initState() {
    super.initState();
    _cubit.load(modelId: widget.product.id, limit: 20);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final product = widget.product;
    final description = TranslationUtils.getLocalizedDescription(
      context: context,
      descriptionKz: product.descriptionKz,
      descriptionRu: product.descriptionRu,
      descriptionEn: product.descriptionEn,
    );
    final firstPhoto = (product.photoUrls?.isNotEmpty ?? false)
        ? product.photoUrls!.first
        : null;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: SafeArea(
          child: BlocBuilder<ReviewsCubit, ReviewsState>(
            builder: (context, state) {
              final count = state.total;
              return Column(
                children: [
                  // App bar
                  SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          onPressed: () => context.pop(),
                          child: SvgPicture.asset(
                            'assets/icons/arrow_left.svg',
                            width: 24,
                            height: 24,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 48),
                              child: Text(
                                l10n.reviews,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                  fontFamily: 'Gilroy',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: AppRefreshIndicator(
                      onRefresh: () => _cubit.refresh(modelId: product.id),
                      child: LoadMoreListener(
                        hasMore: state.hasMore,
                        onLoadMore: () => _cubit.loadMore(modelId: product.id),
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          slivers: [
                            SliverPadding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate([
                                  _ProductHeaderCard(
                                    description: description.trim().isEmpty
                                        ? (product.name ?? '')
                                        : description,
                                    photoUrl: firstPhoto,
                                    countLabel:
                                        l10n.reviewsCount(count.toString()),
                                  ),
                                  const SizedBox(height: 10),
                                  _ReviewsBlock(state: state, count: count),
                                  const SizedBox(height: 16),
                                  _LeaveReviewButton(
                                    label: l10n.orderLeaveReview,
                                    onTap: () => showReviewComposerSheet(
                                      context: context,
                                      modelId: product.id,
                                      cubit: _cubit,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProductHeaderCard extends StatelessWidget {
  const _ProductHeaderCard({
    required this.description,
    required this.photoUrl,
    required this.countLabel,
  });

  final String description;
  final String? photoUrl;
  final String countLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 72,
              height: 72,
              child: photoUrl != null
                  ? NetworkImageWidget(
                      url: '$imgUrl$photoUrl',
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: const Color(0xFFEFEFEF),
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    fontFamily: 'Gilroy',
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  countLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                    fontFamily: 'Gilroy',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsBlock extends StatelessWidget {
  const _ReviewsBlock({required this.state, required this.count});

  final ReviewsState state;
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isFirstLoad = state.status == ReviewsStatus.loading ||
        state.status == ReviewsStatus.initial;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 4),
            child: Row(
              children: [
                Text(
                  l10n.reviews,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontFamily: 'Gilroy',
                  ),
                ),
                const Spacer(),
                Text(
                  l10n.reviewsCount(count.toString()),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                    fontFamily: 'Gilroy',
                  ),
                ),
              ],
            ),
          ),
          if (isFirstLoad)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CupertinoActivityIndicator()),
            )
          else if (state.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  state.status == ReviewsStatus.error
                      ? l10n.reviewsLoadError
                      : l10n.reviewsEmpty,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                    fontFamily: 'Gilroy',
                  ),
                ),
              ),
            )
          else ...[
            for (int i = 0; i < state.items.length; i++)
              ReviewItem(review: state.items[i], showDivider: i != 0),
            if (state.status == ReviewsStatus.loadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CupertinoActivityIndicator()),
              ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LeaveReviewButton extends StatelessWidget {
  const _LeaveReviewButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(16),
        color: mainColorLight,
        onPressed: onTap,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
