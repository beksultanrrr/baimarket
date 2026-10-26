import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/app_localizations.dart';
import 'section_card.dart';

class BonusTicketsRow extends StatelessWidget {
  const BonusTicketsRow({super.key, required this.ticketsToEarn});

  final int ticketsToEarn;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/create_order/create_order_ticket.svg',
            height: 28,
            width: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.ticketsWillBeAwarded,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          Text(
            '+$ticketsToEarn',
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFF3B47),
            ),
          ),
        ],
      ),
    );
  }
}
