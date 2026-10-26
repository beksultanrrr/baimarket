import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

/// Поле ввода телефона для Казахстана: 🇰🇿 +7 │ (000) 000 00 00.
/// Код страны фиксирован (+7); [onCountryChanged] оставлен для совместимости.
class PhoneNumberInput extends StatefulWidget {
  const PhoneNumberInput({
    super.key,
    required this.controller,
    required this.onCountryChanged,
  });

  final TextEditingController controller;
  final void Function(String dialCode) onCountryChanged;

  @override
  State<PhoneNumberInput> createState() => _PhoneNumberInputState();
}

class _PhoneNumberInputState extends State<PhoneNumberInput> {
  final MaskTextInputFormatter _maskFormatter = MaskTextInputFormatter(
    mask: '(###) ### ## ##',
    filter: {'#': RegExp(r'\d')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: Colors.black54,
      fontFamily: 'Gilroy',
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text('🇰🇿', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          const Text('+7', style: textStyle),
          const SizedBox(width: 12),
          // Вертикальный разделитель между "+7" и номером.
          Container(width: 1, height: 24, color: Colors.black26),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: widget.controller,
              keyboardType: TextInputType.phone,
              cursorColor: Colors.black54,
              inputFormatters: [_maskFormatter],
              style: textStyle,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '(000) 000 00 00',
                hintStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black26,
                  fontFamily: 'Gilroy',
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 18),
                isCollapsed: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
