import 'package:flutter/material.dart';
import 'package:bai_market/features/my_address/data/models/user_address_model.dart';

import '../../../../l10n/app_localizations.dart';

class SelectedAddressCard extends StatelessWidget {
  final UserAddressModel address;
  final VoidCallback onClear;
  const SelectedAddressCard({
    super.key,
    required this.address,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // У старых адресов дома нет — он лежит внутри `addressLine` целиком,
    // поэтому склеиваем только то, что есть.
    final houseNumber = address.houseNumber?.trim() ?? '';
    final line = [address.addressLine, if (houseNumber.isNotEmpty) houseNumber].where((part) => part.isNotEmpty).join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address.label.isEmpty ? l10n.addressFallbackTitle : address.label,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  line,
                  style: const TextStyle(color: Colors.black),
                ),
                if (address.postalCode.isNotEmpty)
                  Text(
                    l10n.postalIndex(address.postalCode),
                    style: const TextStyle(color: Colors.black),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}
