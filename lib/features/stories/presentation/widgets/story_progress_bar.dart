import 'package:flutter/material.dart';

/// Сегментированный индикатор поверх сториз: по полоске на каждую сториз
/// продавца.
///
/// Слушает [progress] через `AnimatedBuilder`, а не через `setState` в
/// родителе: перерисовываться 60 раз в секунду должен только этот виджет.
class StoryProgressBar extends StatelessWidget {
  const StoryProgressBar({
    super.key,
    required this.count,
    required this.currentIndex,
    required this.progress,
  });

  final int count;
  final int currentIndex;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: _Segment(
                index: i,
                currentIndex: currentIndex,
                progress: progress,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.index,
    required this.currentIndex,
    required this.progress,
  });

  final int index;
  final int currentIndex;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    // Пройденные — залиты целиком, будущие — пустые, текущий — по анимации.
    final double staticValue = index < currentIndex ? 1 : 0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 3,
        child: index == currentIndex
            ? AnimatedBuilder(
                animation: progress,
                builder: (_, __) => _Bar(value: progress.value),
              )
            : _Bar(value: staticValue),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: value.clamp(0.0, 1.0),
      minHeight: 3,
      backgroundColor: Colors.white.withValues(alpha: 0.3),
      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
    );
  }
}
