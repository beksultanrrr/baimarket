import 'package:bai_market/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:bai_market/features/collection/presentation/cubit/collection_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_gate.dart';
import '../../../../core/services/share_links.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/utils/translation_utils.dart';
import '../../data/models/product_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
// TODO(reviews): отзывы временно отключены целиком.
// import '../../../reviews/presentation/cubit/reviews_cubit.dart';
import '../cubit/product_cubit.dart';
import '../widgets/product_app_bar.dart';
import '../widgets/product_bottom_bar.dart';
import '../widgets/product_image_grid.dart';
import '../widgets/product_price_section.dart';
import '../widgets/product_related_items.dart';
// TODO(reviews): отзывы временно отключены целиком.
// import '../widgets/product_reviews_section.dart';
import '../widgets/product_seller_info.dart';
import '../widgets/product_tags.dart';
import '../../../live/presentation/widgets/live_shopping_scope.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key, required this.id});
  final String? id;

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  late final ProductCubit _productCubit = ProductCubit();
  late final FavoritesCubit _favCubit = FavoritesCubit();
  final CollectionCubit _relatedCubit = CollectionCubit();
  // TODO(reviews): отзывы временно отключены целиком.
  // final ReviewsCubit _reviewsCubit = ReviewsCubit();
  bool _isFavorite = false;

  int get _productId => int.tryParse(widget.id ?? '') ?? 0;

  @override
  void initState() {
    super.initState();
    _productCubit.getProductDetail(id: _productId);
    _relatedCubit.getCollection(slug: 'all', sort: 'popular');
    // TODO(reviews): отзывы временно отключены целиком.
    // В превью показываем 3 отзыва, но грузим страницу целиком: тот же кубит
    // переиспользуется шитом написания отзыва, которому нужен свежий total.
    // _reviewsCubit.load(modelId: _productId, limit: 10);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CartCubit>().getCart();
    });
  }

  @override
  void dispose() {
    // TODO(reviews): отзывы временно отключены целиком.
    // _reviewsCubit.close();
    super.dispose();
  }

  Future<void> _toggleFavorite(int productId) async {
    final profileCubit = context.read<ProfileCubit>();
    final wantsFavorite = !_isFavorite;
    final ok = await ensureAuthenticated(
      context,
      pendingAction: () {
        if (wantsFavorite) {
          _favCubit.addfavorite(id: productId);
        } else {
          _favCubit.removeFromFavoritesById(id: productId);
        }
        profileCubit.getProfileData();
      },
    );
    if (!ok) return;
    setState(() => _isFavorite = wantsFavorite);
    if (wantsFavorite) {
      _favCubit.addfavorite(id: productId);
    } else {
      _favCubit.removeFromFavoritesById(id: productId);
    }
    profileCubit.getProfileData();
  }

  /// Делимся названием, ценой и ссылкой на Firebase Hosting.
  ///
  /// Ссылка отдельной строкой, а не внутри фразы: мессенджеры так надёжнее
  /// распознают её как URL и не утаскивают в подпись соседние слова.
  Future<void> _onShare(ProductModel product, Rect? origin) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    var name = product.name?.trim() ?? '';
    if (name.isEmpty) {
      name = TranslationUtils.getLocalizedName(
        context: context,
        nameKz: product.descriptionKz ?? '',
        nameRu: product.descriptionRu ?? '',
        nameEn: product.descriptionEn ?? '',
      ).trim();
    }
    if (name.isEmpty) return;

    final message = product.price != null
        ? l10n.shareProductMessage(name, l10n.price(product.price.toString()))
        : l10n.shareProductMessageNoPrice(name);

    try {
      await const ShareService().share(
        message: '$message\n${ShareLinks.product(product.id)}',
        sharePositionOrigin: origin,
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.shareAppError),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _block(Widget child, {bool noRadius = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(noRadius ? 0 : 12)),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocConsumer<ProductCubit, ProductState>(
          bloc: _productCubit,
          listener: (context, state) {
            if (state is ProductGot) {
              _isFavorite = state.productModel.isInFavorite ?? false;
            }
          },
          builder: (context, state) {
            if (state is ProductGot) {
              final product = state.productModel;
              return Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // AppBar
                        SliverToBoxAdapter(
                          child: ProductAppBar(
                            isFavorite: _isFavorite,
                            onFavoriteTap: () => _toggleFavorite(product.id),
                            onShareTap: (origin) => _onShare(product, origin),
                          ),
                        ),

                        // Image Grid — on gray background
                        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: ProductImageGrid(model: product))),

                        // Block 2: Tags + Price + Description
                        SliverToBoxAdapter(
                          child: _block(
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ProductTags(model: product),
                                  const SizedBox(height: 12),
                                  ProductPriceSection(model: product),
                                  const SizedBox(height: 12),
                                  Text(
                                    () {
                                      final desc = TranslationUtils.getLocalizedName(
                                        context: context,
                                        nameKz: product.detailedDescriptionKz ?? product.descriptionKz ?? '',
                                        nameRu: product.detailedDescriptionRu ?? product.descriptionRu ?? '',
                                        nameEn: product.detailedDescriptionEn ?? product.descriptionEn ?? '',
                                      );
                                      return desc.trim().isEmpty ? l10n.defaultDescription : desc;
                                    }(),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black, fontFamily: 'Gilroy', height: 1.5),
                                    maxLines: 5,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 10)),

                        // Block 3: Seller Info — скрываем целиком, если бэк не
                        // отдал продавца (поле nullable по контракту).
                        if (product.seller != null) ...[
                          SliverToBoxAdapter(
                            child: _block(
                              ProductSellerInfo(
                                name: product.seller!.displayName,
                                avatarUrl: product.seller!.avatarUrl,
                                orderCount: product.seller!.ordersCount,
                                onTap: () => liveAwarePush(
                                  context,
                                  '/seller/${product.seller!.id}',
                                  extra: {'title': product.seller!.displayName},
                                ),
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 10)),
                        ],

                        // TODO(reviews): отзывы временно отключены целиком.
                        // Block 4: Reviews
                        // SliverToBoxAdapter(
                        //   child: _block(
                        //     Padding(
                        //       padding: const EdgeInsets.all(16),
                        //       child: BlocProvider.value(
                        //         value: _reviewsCubit,
                        //         child: ProductReviewsSection(product: product),
                        //       ),
                        //     ),
                        //   ),
                        // ),
                        //
                        // const SliverToBoxAdapter(child: SizedBox(height: 8)),

                        // Block 5: Related Products
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: BlocBuilder<CollectionCubit, CollectionState>(
                              bloc: _relatedCubit,
                              builder: (context, relatedState) {
                                if (relatedState is CollectionGot) {
                                  return ProductRelatedItems(products: relatedState.collection.products);
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      ],
                    ),
                  ),

                  // Bottom Bar — pinned to bottom
                  ProductBottomBar(model: product),
                ],
              );
            }

            // Мягко удалённый товар: GET /model/:id вернул 404. Карточку могли
            // открыть по ссылке или из истории заказов.
            if (state is ProductNotFound) {
              return _ProductMessageView(message: l10n.productUnavailable);
            }

            if (state is ProductGetError) {
              return _ProductMessageView(
                message: l10n.error(''),
                onRetry: () => _productCubit.getProductDetail(
                  id: int.tryParse(widget.id ?? '') ?? 0,
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

/// Заглушка на весь экран: «товар больше не доступен» либо ошибка загрузки.
class _ProductMessageView extends StatelessWidget {
  const _ProductMessageView({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    // Товара больше нет. Внутри эфира это значит «вернуться к
                    // стриму», а не «уйти на главную».
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        liveAwareDismiss(context);
                      }
                    },
                    child: Text(l10n.goToShopping),
                  ),
                  if (onRetry != null)
                    TextButton(onPressed: onRetry, child: Text(l10n.tryAgain)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
