import 'package:flutter/material.dart';

const Color mainColorDark = Color(0xFF5FB02A);   // тёмный зелёный (текст на кнопках)
const Color mainColorLight = Color(0xFF71CD32);  // основной зелёный
const Color seconColor = Color(0xFF71CD32);      // фон кнопок
const Color lightGray = Color(0xFFF7F7F7);

/// Тёмный цвет primary-кнопок («Получить код», «Подтвердить», «В корзине»).
const Color darkButtonColor = Color(0xFF17181C);

/// Светло-зелёная подложка (Plus-бейдж, тег «Скидка»).
const Color accentSoftGreen = Color(0xFFD4F4C1);

/// Розовая подложка тега «Новинка».
const Color accentSoftPink = Color(0xFFFFD8DF);

/// Тонкая рамка карточек и чипов — `#000000` при 7% (`#00000012` в записи
/// Figma, где альфа идёт последней). Ширина по макету — [kHairlineWidth].
const Color hairlineBorder = Color(0x12000000);
const double kHairlineWidth = 1.5;

/// Заливка полей ввода — `#000000` при 3%.
const Color fieldFill = Color(0x08000000);

/// Вторичный текст: подписи-плейсхолдеры, «+7» в поле телефона — `#000000`
/// при 50%.
const Color secondaryText = Color(0x80000000);
