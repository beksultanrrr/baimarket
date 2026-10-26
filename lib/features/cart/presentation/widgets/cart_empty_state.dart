import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/app_pallete.dart';
import '../../../../l10n/app_localizations.dart';

/// Подпись под заголовком — `#000000` при 40% (в записи Figma `#00000066`).
/// Во Flutter альфа идёт первой, поэтому `0x66000000`.
const Color _subtitleColor = Color(0x66000000);

class CartEmptyState extends StatelessWidget {
  const CartEmptyState({super.key, required this.onGoShopping});
  final VoidCallback onGoShopping;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset('assets/icons/bag-2.svg', height: 85, width: 85),
          const SizedBox(height: 10),
          Text(
            l10n.cartEmpty,
            style: const TextStyle(fontFamily: 'Gilroy', fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.addedItemsWillAppearHere,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Gilroy', fontSize: 14, fontWeight: FontWeight.w400, color: _subtitleColor, height: 1.3),
          ),
          const SizedBox(height: 10),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onGoShopping,
            child: Container(
              height: 56,
              // Ширина по контенту, а не фиксированная: в kk подпись длиннее
              // русской и в 220pt уже не помещалась.
              padding: const EdgeInsets.symmetric(horizontal: 48),
              decoration: BoxDecoration(color: darkButtonColor, borderRadius: BorderRadius.circular(14)),
              alignment: Alignment.center,
              child: Text(
                l10n.goToShopping,
                style: const TextStyle(fontFamily: 'Gilroy', fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
