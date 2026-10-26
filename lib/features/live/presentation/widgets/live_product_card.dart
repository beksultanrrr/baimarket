import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/app_pallete.dart';
import '../../../../core/urls.dart';
import '../../../../core/widgets/plus_price_badge.dart';
import '../../../../core/widgets/show_image.dart';
import '../../../catalog/data/models/category_product_model.dart';
import '../../../../l10n/app_localizations.dart';

/// Карточка товара для frame 37 «Товары в стриме».
/// Включает: фаворит-сердце, картинку, цены (актуальная red + старая
/// перечёркнутая), Plus-цену, остаток на складе, кнопку Купить /
/// Нет в наличии в зависимости от `inStockCount`.
class LiveProductCard extends StatelessWidget {
  const LiveProductCard({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onBuyTap,
  });

  final CategoryProductModel product;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onBuyTap;

  // `null` — остаток неизвестен (например, товар приехал из эфира, а не
  // из каталога). Раньше здесь стоял `?? 0`, и такие товары показывались
  // как «нет в наличии», хотя они есть.
  bool get _outOfStock =>
      product.inStockCount != null && product.inStockCount! <= 0;

  String _formatPrice(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buf.write(s[i]);
      count++;
      if (count == 3 && i != 0) {
        buf.write(' ');
        count = 0;
      }
    }
    return '${buf.toString().split('').reversed.join()}₸';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final price = product.price ?? 0;
    final oldPrice = product.oldPrice;
    final stock = product.inStockCount ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: NetworkImageWidget(
                      url: (product.photoUrls != null &&
                              product.photoUrls!.isNotEmpty)
                          ? '$imgUrl${product.photoUrls![0]}'
                          : '',
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(28, 28),
                    onPressed: onFavoriteTap,
                    child: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite
                          ? const Color(0xFFEC1B6E)
                          : const Color(0xFFD9D9D9),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  _formatPrice(price),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEC1B6E),
                    height: 1.0,
                  ),
                ),
              ),
              if (oldPrice != null && oldPrice > price) ...[
                const SizedBox(width: 4),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: Text(
                      _formatPrice(oldPrice),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF8C8C8C),
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Color(0xFF8C8C8C),
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (product.plusPrice != null) ...[
            const SizedBox(height: 6),
            PlusPriceBadge(plusPrice: product.plusPrice!),
          ],
          const SizedBox(height: 6),
          _StockBadge(count: stock),
          const SizedBox(height: 6),
          Text(
            _description(product),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF8C8C8C),
              height: 1.25,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _outOfStock ? null : onBuyTap,
              child: Container(
                decoration: BoxDecoration(
                  color: _outOfStock
                      ? const Color(0xFFEFEFEF)
                      : mainColorLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  _outOfStock ? l10n.outOfStock : l10n.buy,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _outOfStock
                        ? const Color(0xFF9A9A9A)
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _description(CategoryProductModel p) =>
      p.descriptionRu ?? p.descriptionKz ?? p.descriptionEn ?? p.name ?? '';
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.count});
  final int count;

  bool get _empty => count <= 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF2BB673),
            ),
            child: const Icon(Icons.check, size: 10, color: Colors.white),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              AppLocalizations.of(context)!.stockLeft(count),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _empty ? const Color(0xFFEC1B6E) : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

