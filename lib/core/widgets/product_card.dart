import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/auth_gate.dart';
import '../models/collection_badge_model.dart';
import '../urls.dart';
import 'plus_price_badge.dart';
import '../utils/hex_color.dart';
import '../utils/product_mappers.dart';
import '../utils/translation_utils.dart';
import 'show_image.dart';
import '../../l10n/app_localizations.dart';
import '../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../features/catalog/data/models/category_product_model.dart';
import '../../features/favorites/presentation/cubit/favorites_cubit.dart';
import '../../features/live/presentation/widgets/live_shopping_scope.dart';
import '../../features/main/presentation/widgets/favorite_button.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});
  final CategoryProductModel product;

  CollectionBadgeModel? _bySlug(String slug) {
    final list = product.collections;
    if (list == null) return null;
    for (final c in list) {
      if (c.slug == slug) return c;
    }
    return null;
  }

  /// Реальная скидка — это `oldPrice` против `price`. `collections[].discount`
  /// это лейбл и на цену не влияет, поэтому в расчёт не идёт.
  int? get _discountPercent {
    final old = product.oldPrice;
    final cur = product.price;
    if (old == null || cur == null || old <= 0 || cur >= old) return null;
    return ((old - cur) / old * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final plusPrice = product.plusPrice;
    final newCollection = _bySlug('new');
    final discountCollection = _bySlug('discount');
    // Процент на бейдже: сначала лейбл из админки, иначе считаем из цен.
    final discount = discountCollection?.discount ?? _discountPercent;
    final tickets = product.ticketsCount ?? 0;
    // Зачёркнутая цена показывается только если она реально больше текущей.
    final hasOldPrice = _discountPercent != null;
    final isOutOfStock =
        product.inStockCount != null && product.inStockCount == 0;

    return GestureDetector(
      onTap: () {
        liveAwarePush(context, '/product/${product.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                  child: SizedBox(
                    height: 170,
                    width: double.infinity,
                    child: NetworkImageWidget(
                      url: product.photoUrls != null &&
                              product.photoUrls!.isNotEmpty
                          ? '$imgUrl${product.photoUrls![0]}'
                          : '',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Favorite — top right
                Positioned(
                  top: 10,
                  right: 10,
                  child: BlocListener<FavoritesCubit, FavoritesState>(
                    listener: (context, state) {
                      if (state is FavoritesAdded ||
                          state is FavoritesDeleted) {
                        context.read<ProfileCubit>().getProfileData();
                      }
                    },
                    child: FavoriteButton(
                      productId: product.id,
                      isFavorite: product.isInFavorite,
                    ),
                  ),
                ),
                // Badge — bottom left. Цвет берём из админки (`collections[].color`),
                // при отсутствии — исторический градиент.
                if (discount != null)
                  Positioned(
                    bottom: 0,
                    left: 5,
                    child: _DiscountBadge(
                      label: l10n.discount,
                      percent: discount,
                      color: colorFromHex(discountCollection?.color),
                    ),
                  )
                else if (newCollection != null)
                  Positioned(
                    bottom: 0,
                    left: 5,
                    child: _NewBadge(
                      label: l10n.newTag,
                      color: colorFromHex(newCollection.color),
                    ),
                  ),
                // Билеты за покупку одной единицы — bottom right.
                if (tickets > 0)
                  Positioned(
                    bottom: 0,
                    right: 5,
                    child: _TicketsBadge(
                      label: l10n.ticketsBadge(tickets.toString()),
                    ),
                  ),
              ],
            ),

            // ── Info ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l10n.price(product.price?.toString() ?? '0'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xBF000000),
                          fontFamily: GoogleFonts.inter().fontFamily,
                        ),
                      ),
                      if (hasOldPrice) ...[
                        const SizedBox(width: 6),
                        Text(
                          l10n.oldPrice(product.oldPrice.toString()),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: const Color(0x40000000),
                            decoration: TextDecoration.lineThrough,
                            fontFamily: GoogleFonts.inter().fontFamily,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Plus price badge
                  if (plusPrice != null) ...[
                    const SizedBox(height: 8),
                    PlusPriceBadge(plusPrice: plusPrice),
                  ],
                  const SizedBox(height: 8),
                  // Description — fixed 32 px so layout never overflows
                  SizedBox(
                    height: 32,
                    child: Text(
                      TranslationUtils.getLocalizedName(
                        context: context,
                        nameKz: product.descriptionKz ?? product.name ?? '',
                        nameRu: product.descriptionRu ?? product.name ?? '',
                        nameEn: product.descriptionEn ?? product.name ?? '',
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xBF000000),
                        fontFamily: GoogleFonts.roboto().fontFamily,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Cart button
                  _CartButton(product: product, isOutOfStock: isOutOfStock),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge widgets ───────────────────────────────────────────────────────────

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({
    required this.label,
    required this.percent,
    this.color,
  });
  final String label;
  final int percent;

  /// Цвет из `collections[].color`. `null` — исторический градиент.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        gradient: color != null
            ? null
            : const LinearGradient(
                colors: [Color(0xFFF73030), Color(0xFFFF6D6D)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              fontFamily: 'Gilroy',
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '-$percent%',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              fontFamily: 'Gilroy',
            ),
          ),
        ],
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge({required this.label, this.color});
  final String label;

  /// Цвет из `collections[].color`. `null` — исторический градиент.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        gradient: color != null
            ? null
            : const LinearGradient(
                colors: [Color(0xFF28A673), Color(0xFF47CD97)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          fontFamily: 'Gilroy',
        ),
      ),
    );
  }
}

/// «+2 🎟» — билеты за покупку ОДНОЙ единицы товара.
///
/// На checkout билеты считаются по сумме всей корзины, поэтому итог в заказе
/// может отличаться от суммы бейджей — это ожидаемо, бейдж рекламный.
class _TicketsBadge extends StatelessWidget {
  const _TicketsBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF00520B),
              fontFamily: 'Gilroy',
            ),
          ),
          const SizedBox(width: 3),
          SvgPicture.asset('assets/icons/green_ticket.svg', height: 11),
        ],
      ),
    );
  }
}

// ── Cart button ─────────────────────────────────────────────────────────────

class _CartButton extends StatelessWidget {
  const _CartButton({required this.product, required this.isOutOfStock});
  final CategoryProductModel product;
  final bool isOutOfStock;

  static const _buttonStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Color(0xFF00520B),
    fontFamily: 'Gilroy',
  );
  static const _radius = BorderRadius.all(Radius.circular(15));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isOutOfStock) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0x0D000000),
          borderRadius: _radius,
        ),
        child: Center(
          child: Text(
            l10n.notAvailable,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0x40000000),
              fontFamily: 'Gilroy',
            ),
          ),
        ),
      );
    }

    return BlocBuilder<CartCubit, CartState>(
      buildWhen: (prev, next) {
        // Only rebuild when this product's quantity changes
        int qtyOf(CartState s) =>
            s is CartGot
                ? (s.cart.cartItems
                            ?.where((i) => i.model?.id == product.id)
                            .firstOrNull
                            ?.quantity ??
                        0)
                : 0;
        return qtyOf(prev) != qtyOf(next);
      },
      builder: (context, _) {
        final cubit = context.read<CartCubit>();
        final inCart = cubit.quantityOf(product.id) > 0;

        if (inCart) {
          return SizedBox(
            width: double.infinity,
            height: 32,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: _radius,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => cubit.removeCart(id: product.id),
                      child: SvgPicture.asset(
                        'assets/icons/minus_gray.svg',
                        width: 14,
                      ),
                    ),
                  ),
                  Text(
                    '${cubit.quantityOf(product.id)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () async {
                        final ok = await ensureAuthenticated(
                          context,
                          pendingAction: () => cubit.addCart(
                            id: product.id,
                            product: productModelFrom(product),
                          ),
                        );
                        if (!ok) return;
                        cubit.addCart(
                          id: product.id,
                          product: productModelFrom(product),
                        );
                      },
                      child: SvgPicture.asset(
                        'assets/icons/plus_gray.svg',
                        width: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () async {
            final ok = await ensureAuthenticated(
              context,
              pendingAction: () => cubit.addCart(
                id: product.id,
                product: productModelFrom(product),
              ),
            );
            if (!ok) return;
            cubit.addCart(
              id: product.id,
              product: productModelFrom(product),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: const BoxDecoration(color: Color(0xFF71CD32), borderRadius: _radius),
            child: Center(child: Text(l10n.buy, style: _buttonStyle)),
          ),
        );
      },
    );
  }
}

