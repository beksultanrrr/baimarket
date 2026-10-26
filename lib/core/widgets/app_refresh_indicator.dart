import 'package:flutter/material.dart';

import '../app_pallete.dart';
import '../../l10n/app_localizations.dart';

class AppRefreshIndicator extends StatelessWidget {
  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.dark = false,
    this.edgeOffset = 0,
    this.displacement = 28,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final bool dark;
  final double edgeOffset;
  final double displacement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: dark ? Colors.white : mainColorLight,
      backgroundColor: dark ? const Color(0xFF1A1A1A) : Colors.white,
      strokeWidth: 2.2,
      displacement: displacement,
      edgeOffset: edgeOffset,
      elevation: 0,
      semanticsLabel: l10n.pullToRefresh,
      // semanticsValue намеренно не задаём: это значение прогресса для
      // semantics-узла прогресс-бара (диапазон 0…100), и любая нетекстовая
      // строка там валит accessibility-мост Android:
      // «Progress bar value, minValue, and maxValue must be valid numbers».
      // Описание для скринридера несёт semanticsLabel выше.
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      child: child,
    );
  }
}
