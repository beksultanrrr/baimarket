import 'package:flutter/material.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../catalog/data/models/category_product_model.dart';

class ProductRelatedItems extends StatelessWidget {
  const ProductRelatedItems({super.key, required this.products});
  final List<CategoryProductModel> products;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (products.isEmpty) return const SizedBox.shrink();

    final count = products.length > 6 ? 6 : products.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.relatedProducts,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.black,
              fontFamily: 'Gilroy'
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 342,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: count,
            itemBuilder: (context, index) {
              return SizedBox(
                width: 180,
                child: Padding(
                  padding: EdgeInsets.only(right: index == count - 1 ? 0 : 10),
                  child: ProductCard(product: products[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
