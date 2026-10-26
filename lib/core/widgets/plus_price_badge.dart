import 'package:bai_market/core/app_pallete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';

class PlusPriceBadge extends StatelessWidget {
  const PlusPriceBadge({super.key, required this.plusPrice});
  final int plusPrice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: accentSoftGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/main_plus_2.svg',
                height: 22,
                width: 22,
              ),
              const SizedBox(width: 4),
              // Ширина подобрана так, чтобы подпись всегда ложилась в две
              // строки («Plus пен» / «алсаңыз») — во всех трёх локалях.
              SizedBox(
                width: 52,
                child: Text(
                  l10n.plusPrice,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Gilroy',
                    height: 1.1,
                    color: Color(0xFF39951F),
                  ),
                ),
              ),
            ],
          ),
          Text(
            l10n.price(plusPrice.toString()),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: GoogleFonts.inter().fontFamily,
              color:  Color(0xFF39951F),
            ),
          ),
        ],
      ),
    );
  }
}
