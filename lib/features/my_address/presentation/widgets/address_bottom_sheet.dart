import 'package:bai_market/core/app_pallete.dart';
import 'package:bai_market/core/widgets/main_button.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/user_address_model.dart';
import 'address_tile.dart';

class AddressBottomSheet extends StatelessWidget {
  final List<UserAddressModel> addresses;
  final int? selectedId;
  final Function(UserAddressModel) onSelect;
  final VoidCallback onAdd;

  const AddressBottomSheet({
    super.key,
    required this.addresses,
    required this.selectedId,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                l10n.selectAddress,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: mainColorLight,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (addresses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  l10n.noSavedAddresses,
                  style: const TextStyle(color: Colors.black54, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...addresses.map(
                (address) => AddressTile(
                  address: address,
                  selected: selectedId == address.id,
                  onTap: () => onSelect(address),
                ),
              ),
            const SizedBox(height: 16),
            MainButton(onPressed: onAdd, text: l10n.addAddress, color: mainColorLight),
          ],
        ),
      ),
    );
  }
}
