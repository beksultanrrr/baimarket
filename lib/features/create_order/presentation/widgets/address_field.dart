import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/app_pallete.dart';
import '../../../../l10n/app_localizations.dart';

/// Улица — и ТОЛЬКО улица. Дом и квартира уходят отдельным полем
/// ([HouseNumberField]): бэк ждёт их в `houseNumber`, а не в `deliveryAddress`.
class AddressField extends StatelessWidget {
  const AddressField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _CheckoutField(
      label: l10n.deliveryAddress,
      hint: l10n.specifyDeliveryAddress,
      controller: controller,
      keyboardType: TextInputType.streetAddress,
      autofillHints: const [AutofillHints.streetAddressLine1],
    );
  }
}

/// Дом и квартира одной строкой — «150, кв. 25». Поле обязательное: это
/// единственное, что доезжает до Казпочты помимо улицы и города, поэтому
/// подъезд и этаж покупатель пишет сюда же.
class HouseNumberField extends StatelessWidget {
  const HouseNumberField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _CheckoutField(
      label: l10n.houseNumberLabel,
      hint: l10n.houseNumberHint,
      controller: controller,
      keyboardType: TextInputType.text,
      // Свободный текст: «12А» и «15/2» бэк принимает, ограничение только
      // по длине.
      inputFormatters: [LengthLimitingTextInputFormatter(100)],
    );
  }
}

class _CheckoutField extends StatelessWidget {
  const _CheckoutField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.autofillHints,
    this.inputFormatters,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            label,
            style: const TextStyle(fontFamily: 'Gilroy', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF6E6E6E)),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            filled: true,
            fillColor: lightGray,
            isCollapsed: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintText: hint,
            hintStyle: const TextStyle(fontFamily: 'Gilroy', fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF9A9A9A)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          style: const TextStyle(fontFamily: 'Gilroy', fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black),
          enableSuggestions: true,
          autocorrect: true,
        ),
      ],
    );
  }
}
