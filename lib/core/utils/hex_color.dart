import 'dart:ui';

/// Парсит hex-цвет из ответа бэка (`collections[].color`, например `"#FA374D"`).
///
/// Принимает `#RGB`, `#RRGGBB`, `#AARRGGBB` и те же формы без `#`.
/// Возвращает `null` на любом мусоре — вызывающий код должен иметь фолбэк,
/// потому что цвет заводится руками в админке.
Color? colorFromHex(String? hex) {
  if (hex == null) return null;
  var value = hex.trim();
  if (value.isEmpty) return null;
  if (value.startsWith('#')) value = value.substring(1);

  // #RGB → #RRGGBB
  if (value.length == 3) {
    value = value.split('').map((c) => '$c$c').join();
  }
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return null;

  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return null;
  return Color(parsed);
}
