import 'package:flutter/material.dart';

import '../../../../core/app_pallete.dart';
import '../../../../l10n/app_localizations.dart';
import 'order_filter.dart';

class OrdersFilterTabs extends StatelessWidget {
  const OrdersFilterTabs({super.key, required this.selected, required this.onSelected});

  final OrderFilter selected;
  final ValueChanged<OrderFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: OrderFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = OrderFilter.values[index];
          final isSelected = filter == selected;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelected(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                // По макету активный чип чёрный, а не зелёный; невыбранные —
                // белые с тонкой рамкой и тёмным (не серым) текстом.
                color: isSelected ? darkButtonColor : Colors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: isSelected ? darkButtonColor : hairlineBorder, width: kHairlineWidth),
              ),
              alignment: Alignment.center,
              child: Text(
                orderFilterLabel(l10n, filter),
                style: TextStyle(fontFamily: 'Gilroy', fontSize: 14, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : darkButtonColor, height: 1),
              ),
            ),
          );
        },
      ),
    );
  }
}
