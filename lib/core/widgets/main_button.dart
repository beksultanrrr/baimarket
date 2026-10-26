import 'package:bai_market/core/app_pallete.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Главная кнопка приложения.
///
/// Вид по макету «Мои данные» (Frame 19): чёрная плашка высотой 60 со
/// скруглением 15. Кнопка общая — так она выглядит на всех восьми экранах,
/// где стоит: «Мои данные», оформление заказа, четыре экрана адресов,
/// баннер и онбординг.
class MainButton extends StatelessWidget {
  const MainButton({super.key, required this.onPressed, required this.text, this.color, this.textColor});
  final VoidCallback? onPressed;
  final String text;
  final Color? textColor;

  /// Заливка. По умолчанию чёрная — так на «Моих данных», оформлении заказа,
  /// баннере и онбординге. Экраны адресов передают [mainColorLight]: там по
  /// макету кнопка зелёная.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(color: color ?? darkButtonColor, borderRadius: BorderRadius.circular(15)),
      child: CupertinoButton(
        onPressed: onPressed,
        child: Center(
          child: Text(
            text,
            style: TextStyle(fontFamily: 'Gilroy', fontSize: 20, fontWeight: FontWeight.w500, color: textColor ?? Colors.white),
          ),
        ),
      ),
    );
  }
}
