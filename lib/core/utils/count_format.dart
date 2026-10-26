/// Короткая запись счётчиков для бейджей: 999 → "999", 1000 → "1K",
/// 1200 → "1.2K".
///
/// Вынесено из приватного `_RailItem._fmt`
/// (`features/live/presentation/widgets/live_action_rail.dart`), чтобы бейдж
/// корзины в нижней навигации и рейл эфира считали одинаково.
String formatCountShort(int value) {
  if (value >= 1000) {
    final k = value / 1000;
    return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}K';
  }
  return value.toString();
}
