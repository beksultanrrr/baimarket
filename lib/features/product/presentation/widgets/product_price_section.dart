import 'package:flutter/material.dart';
import 'product_plus_price_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/product_model.dart';

class ProductPriceSection extends StatelessWidget {
  const ProductPriceSection({super.key, required this.model});
  final ProductModel model;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final plusPrice = model.plusPrice;
    // Зачёркнутая цена — только если она реально больше текущей.
    final hasOldPrice = model.oldPrice != null &&
        model.price != null &&
        model.oldPrice! > model.price!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        // Main price row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              l10n.price(model.price?.toString() ?? '0'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            if (hasOldPrice) ...[
              const SizedBox(width: 8),
              Text(
                l10n.oldPrice(model.oldPrice.toString()),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade500,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ],
        ),
        if (plusPrice != null) ...[
          const SizedBox(height: 10),
          ProductPlusPriceBadge(plusPrice: plusPrice),
        ],
      ],
    );
  }
}
