import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/widgets/product_card.dart';
import '../../../../core/widgets/shimmer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../catalog/data/models/category_product_model.dart';
import '../../../raffle/presentation/widgets/raffle_sort_sheet.dart';
import '../cubit/seller_store_cubit.dart';

/// Сетка товаров магазина: счётчик, сортировка, карточки, футер догрузки.
///
/// Свёрстано по образцу `raffle_products_section.dart` — те же 2 колонки,
/// `mainAxisExtent: 342` и отступы. Отличия: счётчик берёт `total` (общее число
/// товаров магазина, а не размер страницы), карточки рисуются `ProductCard`
/// напрямую (mock-id тут нет), снизу футер пагинации.
///
/// Иконки фильтра здесь намеренно нет: фильтров по цене/наличию/новинкам на
/// публичных ручках не существует, кнопка была бы мёртвой.
class SellerProductsSection extends StatelessWidget {
  const SellerProductsSection({super.key, required this.models, required this.total, required this.sort, required this.status, required this.onSortChanged});

  final List<CategoryProductModel> models;
  final int total;
  final String sort;
  final SellerStoreStatus status;
  final ValueChanged<String> onSortChanged;

  bool get _isFirstLoad => status == SellerStoreStatus.loading || status == SellerStoreStatus.initial;

  /// Магазин без товаров: секцию надо растянуть на весь остаток вьюпорта,
  /// иначе из-под белого блока торчит зелёный фон `Scaffold`. Решает не сам
  /// виджет, а `seller_store_page.dart` — ему выбирать `SliverFillRemaining`
  /// вместо `SliverToBoxAdapter`, и только в этом случае [_Empty] внутри
  /// становится `Expanded` (в обычном сливере высота не ограничена).
  ///
  /// Скелет первой загрузки сюда не входит намеренно: он рисует `GridView`,
  /// а `SliverFillRemaining(hasScrollBody: false)` спрашивает у ребёнка
  /// intrinsic-высоту, которую скроллящиеся вьюпорты не умеют считать.
  bool get fillsViewport => !_isFirstLoad && models.isEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                '$total ${l10n.products}',
                style: const TextStyle(fontFamily: 'Gilroy', fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
              ),
              _SortTrigger(
                label: raffleSortLabel(l10n, sort),
                onTap: () async {
                  final picked = await showRaffleSortSheet(context: context, current: sort);
                  if (picked != null && picked != sort) onSortChanged(picked);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isFirstLoad)
            const _Skeleton()
          else if (models.isEmpty)
            Expanded(child: _Empty(message: l10n.sellerProductsEmpty))
          else ...[
            Opacity(
              opacity: status == SellerStoreStatus.sorting ? 0.5 : 1,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: models.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, mainAxisExtent: 342),
                itemBuilder: (_, i) => ProductCard(product: models[i]),
              ),
            ),
            if (status == SellerStoreStatus.loadingMore)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Center(child: CupertinoActivityIndicator()),
              ),
          ],
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
            style: const TextStyle(fontFamily: 'Gilroy', fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, mainAxisExtent: 342),
      itemBuilder: (_, __) => const SimpleShimmer(borderRadius: 16),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontFamily: 'Gilroy', fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
      ),
    );
  }
}
