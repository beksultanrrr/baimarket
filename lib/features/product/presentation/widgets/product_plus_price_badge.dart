import 'package:bai_market/core/app_pallete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../l10n/app_localizations.dart';

class ProductPlusPriceBadge extends StatelessWidget {
  const ProductPlusPriceBadge({super.key, required this.plusPrice});
  final int plusPrice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: accentSoftGreen, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset('assets/icons/main_plus_2.svg', height: 24, width: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(l10n.plusPrice, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Gilroy', color: Color(0xFF39951F))),
                const Spacer(),
                Text(l10n.price(plusPrice.toString()), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.inter().fontFamily, color: Color(0xFF39951F))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
