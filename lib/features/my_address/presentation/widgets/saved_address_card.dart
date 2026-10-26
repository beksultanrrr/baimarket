import 'package:flutter/material.dart';

import '../../../../core/app_pallete.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/user_address_model.dart';

class SavedAddressCard extends StatelessWidget {
  final UserAddressModel address;
  final VoidCallback onDelete;

  const SavedAddressCard({super.key, required this.address, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hairlineBorder, width: kHairlineWidth),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.addressLabeled(address.label),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: mainColorLight),
                ),
                const SizedBox(height: 8),
                Text(
                  address.addressLine,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.black38, height: 1.4),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.postalIndex(address.postalCode),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
                ),
              ],
            ),
          ),
          // Меню в стиле проекта: белая карточка со скруглением 16 и той же
          // тонкой рамкой, что у самой карточки адреса, вместо серой
          // Material-плашки с дефолтной тенью.
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black38),
            color: Colors.white,
            elevation: 4,
            shadowColor: hairlineBorder,
            position: PopupMenuPosition.under,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: hairlineBorder, width: kHairlineWidth),
            ),
            onSelected: (value) {
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                value: 'delete',
                height: 48,
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded, color: Color(0xFFE53935), size: 20),
                    const SizedBox(width: 10),
                    Text(
                      l10n.deleteAction,
                      style: const TextStyle(fontFamily: 'Gilroy', fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFFE53935)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
