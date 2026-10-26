import 'package:flutter/material.dart';

import '../../../../core/app_pallete.dart';
import '../../../../l10n/app_localizations.dart';
import 'order_filter.dart';

class OrderStatusTag extends StatelessWidget {
  const OrderStatusTag({super.key, required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final group = orderFilterForStatus(status);

    // По макету: пастельная заливка + насыщенный текст того же семейства.
    // Пары совпадают с градиентами плиток главной, поэтому берём из палитры.
    final (label, background, foreground) = switch (group) {
      OrderFilter.active => (
          l10n.orderTagActive,
          accentSoftGreen,
          mainColorDark,
        ),
      OrderFilter.completed => (
          l10n.orderTagCompleted,
          accentSoftPink,
          const Color(0xFFFF2C61),
        ),
      OrderFilter.returns => (
          l10n.orderTagReturn,
          const Color(0xFFE8DFFE),
          const Color(0xFF7654C7),
        ),
      OrderFilter.all => (
          status ?? '',
          const Color(0xFFEFEFEF),
          const Color(0xFF9E9E9E),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
