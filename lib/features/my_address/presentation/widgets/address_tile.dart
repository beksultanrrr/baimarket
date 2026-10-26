import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/app_pallete.dart';
import '../../data/models/user_address_model.dart';

class AddressTile extends StatelessWidget {
  final UserAddressModel address;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const AddressTile({
    super.key,
    required this.address,
    required this.selected,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? mainColorLight : Colors.transparent,
            width: 1,
          ),
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
                    style: TextStyle(
                      color: mainColorLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    address.addressLine,
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.postalIndex(address.postalCode),
                    style: TextStyle(color: Colors.black, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              size: 24,
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? mainColorLight : Colors.grey,
            ),
            if (onDelete != null)
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
