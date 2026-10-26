import 'package:flutter/material.dart';

import '../../../../core/app_pallete.dart';

class BaseAvatarTile extends StatelessWidget {
  const BaseAvatarTile({
    super.key,
    required this.initial,
    this.selected = true,
    this.onTap,
  });

  final String initial;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        // Макет: 80×80, скругление 15, заливка #DCF3CC, буква #00520B.
        // Обводки у выбранной плитки в макете нет — убрана намеренно.
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          color: accentSoftGreen,
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.center,
        child: Text(
          initial.isEmpty ? '?' : initial.characters.first.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Color(0xFF00520B),
          ),
        ),
      ),
    );
  }
}
