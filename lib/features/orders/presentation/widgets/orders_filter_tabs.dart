import 'package:flutter/material.dart';

import '../../../../core/app_pallete.dart';
import '../../../../l10n/app_localizations.dart';
import 'order_filter.dart';

class OrdersFilterTabs extends StatelessWidget {
  const OrdersFilterTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

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
                color: isSelected ? mainColorLight : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? mainColorLight : const Color(0xFFE8E8E8),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                orderFilterLabel(l10n, filter),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFFB8B8B8),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
