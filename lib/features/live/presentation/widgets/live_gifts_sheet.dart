import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/product_mappers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../catalog/data/models/category_product_model.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../seller/data/datasources/seller_services.dart';
import '../../../seller/domain/repositories/seller_repository.dart';
import '../../live_flags.dart';
import 'live_gift_card.dart';
import 'live_product_card.dart';
import 'live_shopping_scope.dart';
import 'sheet_close_button.dart';

/// Шит «Товары в стриме».
///
/// Раньше сюда приезжала захардкоженная коллекция `new`, никак не связанная с
/// эфиром. Теперь это витрина продавца, который сейчас вещает, — `GET
/// /seller/:id/models`, та же ручка, что и у экрана магазина.
Future<void> showLiveGiftsSheet({
  required BuildContext context,
  required int sellerId,
  int? pinnedProductId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    // Тег обязателен: без него closeAll упирается в этот шит и молча
    // перестаёт работать для всего, что открыто над ним.
    routeSettings: const RouteSettings(name: kLiveSheetRouteName),
    builder: (sheetCtx) => _LiveProductsSheet(
      sellerId: sellerId,
      pinnedProductId: pinnedProductId,
    ),
  );
}

class _LiveProductsSheet extends StatefulWidget {
  const _LiveProductsSheet({required this.sellerId, this.pinnedProductId});

  final int sellerId;
  final int? pinnedProductId;

  @override
  State<_LiveProductsSheet> createState() => _LiveProductsSheetState();
}

class _LiveProductsSheetState extends State<_LiveProductsSheet> {
  final SellerRepository _repo = SellerServices();

  List<CategoryProductModel>? _products;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _repo.getSellerProducts(
      id: widget.sellerId,
      sort: 'popular',
      limit: 20,
      skip: 0,
    );
    if (!mounted) return;
    switch (result) {
      case SellerProductsLoaded(:final data):
        setState(() => _products = _pinnedFirst(data.models));
      case SellerProductsNotFound():
      case SellerProductsFailed():
        setState(() => _failed = true);
    }
  }

  /// Закреплённый товар — первым: иначе шит и оверлей поверх видео
  /// показывают разное, и непонятно, о чём именно говорит продавец.
  List<CategoryProductModel> _pinnedFirst(List<CategoryProductModel> models) {
    final pinnedId = widget.pinnedProductId;
    if (pinnedId == null) return models;
    final index = models.indexWhere((m) => m.id == pinnedId);
    if (index <= 0) return models;
    final copy = [...models];
    copy.insert(0, copy.removeAt(index));
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.streamProductsTitle,
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          SheetCloseButton(
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    _body(l10n),
                    if (kLiveGiftsEnabled) ...[
                      const SizedBox(height: 28),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                        child: Text(
                          l10n.streamGiftsTitle,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: LiveGiftCard(title: ''),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _body(AppLocalizations l10n) {
    if (_failed) {
      return _Message(text: l10n.streamsLoadError);
    }
    final products = _products;
    if (products == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (products.isEmpty) {
      return _Message(text: l10n.hostNoProducts);
    }
    return _ProductGrid(products: products);
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 14,
            color: Color(0xFF8C8C8C),
          ),
        ),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products});
  final List<CategoryProductModel> products;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.52,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        return BlocBuilder<FavoritesCubit, FavoritesState>(
          builder: (context, fs) {
            final isFav = _isFavorite(p, fs) || p.isInFavorite;
            return LiveProductCard(
              product: p,
              isFavorite: isFav,
              onFavoriteTap: () => _toggleFavorite(context, p, isFav),
              onBuyTap: () => _addToCart(context, p),
            );
          },
        );
      },
    );
  }

  bool _isFavorite(CategoryProductModel p, FavoritesState s) {
    if (s is FavoritesGot) return s.favorites.any((f) => f.id == p.id);
    return false;
  }

  void _toggleFavorite(
    BuildContext context,
    CategoryProductModel p,
    bool isFavorite,
  ) {
    final cubit = context.read<FavoritesCubit>();
    if (isFavorite) {
      cubit.removeFromFavoritesById(id: p.id);
    } else {
      cubit.addfavorite(id: p.id);
    }
  }

  void _addToCart(BuildContext context, CategoryProductModel p) {
    final cart = context.read<CartCubit>();
    // Контекст рут-навигатора берём заранее: после Navigator.pop локальный
    // контекст шита размонтирован, а корзину надо открыть поверх эфира.
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    // product: обязателен — без него позиции нет в локальном кэше и счётчик
    // корзины не шевельнётся до ответа сервера.
    cart.addCart(id: p.id, product: productModelFrom(p));
    Navigator.pop(context);
    openLiveCartSheet(rootContext);
  }
}
