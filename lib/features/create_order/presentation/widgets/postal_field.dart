import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../core/app_pallete.dart';
import '../../../../l10n/app_localizations.dart';

/// Почтовый индекс. Ровно шесть цифр — на этом настаивает и бэк, и Казпочта,
/// поэтому маска не пускает ничего лишнего.
///
/// Расчёт доставки страница дёргает из слушателя [controller]: индекс
/// подставляется ещё и из сохранённого адреса, а `onChanged` на такую
/// подстановку не срабатывает.
class PostalField extends StatelessWidget {
  const PostalField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final postalFormatter = MaskTextInputFormatter(
      mask: '######', // 6 цифр
      filter: {"#": RegExp(r'\d')},
      type: MaskAutoCompletionType.lazy,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            l10n.postalCode,
            style: const TextStyle(fontFamily: 'Gilroy', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF6E6E6E)),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          inputFormatters: [postalFormatter],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: lightGray,
            isCollapsed: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintText: '123456',
            hintStyle: const TextStyle(fontFamily: 'Gilroy', fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF9A9A9A)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          autofillHints: const [AutofillHints.postalCode],
          style: const TextStyle(fontFamily: 'Gilroy', fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black),
          enableSuggestions: true,
          autocorrect: true,
        ),
      ],
    );
  }
}
