import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/models/cart_change_model.dart';

/// Что сервер поменял в корзине при синхронизации с каталогом: закончившиеся
/// товары удалены, цены переписаны на актуальные.
///
/// Снекбар показывает только первое изменение — здесь перечисляем все, потому
/// что именно на странице корзины пользователь может на это отреагировать.
class CartChangesBanner extends StatelessWidget {
  const CartChangesBanner({super.key, required this.changes});

  final List<CartChangeModel> changes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lines = <String>[];
    for (final change in changes) {
      final name = change.name;
      if (name == null || name.isEmpty) continue;
      switch (change.kind) {
        case CartChangeKind.removed:
          lines.add(l10n.cartItemRemovedByStock(name));
        case CartChangeKind.quantityReduced:
          lines.add(
            l10n.cartItemQuantityReduced(
              name,
              (change.newQuantity ?? 0).toString(),
            ),
          );
        case CartChangeKind.priceChanged:
          lines.add(l10n.cartItemPriceChanged(name));
        case CartChangeKind.unknown:
          break;
      }
    }
    if (lines.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFFB26A00),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      line,
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8A5200),
                        height: 1.3,
                      ),
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
