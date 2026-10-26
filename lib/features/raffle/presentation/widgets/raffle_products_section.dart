import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/widgets/shimmer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/raffle_products_response.dart';
import 'raffle_product_tile.dart';
import 'raffle_sort_sheet.dart';

class RaffleProductsSection extends StatelessWidget {
  const RaffleProductsSection({
    super.key,
    required this.products,
    required this.sort,
    required this.isSorting,
    required this.onSortChanged,
  });

  final RaffleProductsResponse? products;
  final String sort;
  final bool isSorting;
  final ValueChanged<String> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final count = products?.total ?? products?.models.length ?? 0;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$count ${l10n.products}',
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              _SortTrigger(
                label: raffleSortLabel(l10n, sort),
                onTap: () async {
                  final picked = await showRaffleSortSheet(
                    context: context,
                    current: sort,
                  );
                  if (picked != null && picked != sort) {
                    onSortChanged(picked);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (products == null)
            const _Skeleton()
          else if (products!.models.isEmpty)
            _Empty(message: l10n.raffleProductsEmpty)
          else
            Opacity(
              opacity: isSorting ? 0.5 : 1,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: products!.models.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 342,
                ),
                itemBuilder: (_, i) =>
                    RaffleProductTile(product: products!.models[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _SortTrigger extends StatelessWidget {
  const _SortTrigger({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 10),
          SvgPicture.asset('assets/icons/sort.svg'),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 342,
      ),
      itemBuilder: (_, __) => const SimpleShimmer(borderRadius: 16),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }
}
