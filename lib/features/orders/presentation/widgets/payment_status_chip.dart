import 'package:flutter/material.dart';

import '../../../../core/app_pallete.dart';
import '../../../../l10n/app_localizations.dart';

class PaymentStatusChip extends StatelessWidget {
  const PaymentStatusChip({super.key, required this.isPaid, required this.price});

  final bool isPaid;
  final int price;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formatted = _formatPrice(price);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: hairlineBorder, width: kHairlineWidth),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isPaid ? l10n.paid : l10n.unpaid,
            style: const TextStyle(fontFamily: 'Gilroy', fontSize: 12, fontWeight: FontWeight.w500, color: mainColorDark),
          ),
          const SizedBox(width: 10),
          Text(
            '$formatted₸',
            style: const TextStyle(fontFamily: 'Gilroy', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
          ),
        ],
      ),
    );
  }
}

String _formatPrice(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i != 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}
