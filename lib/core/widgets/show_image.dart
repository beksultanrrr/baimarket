import 'package:flutter/material.dart';
import 'shimmer.dart';

// Спокойный нейтральный фон + по центру брендовая mock-картинка
// (НЕ растянутая на cover — иначе выглядит как реальное фото товара).
const Color _kFallbackBg = Color(0xFFF2F2F2);
const String _kFallbackAsset = 'assets/images/mockiamge.png';

class NetworkImageWidget extends StatelessWidget {
  const NetworkImageWidget({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.dark = false,
    this.solidFallback = false,
    this.fallbackColor,
    this.fallbackScale = 0.55,
  });

  final String url;
  final BoxFit fit;
  final bool dark;

  /// Фон заглушки. По умолчанию — нейтральный серый; экраны, где картинка
  /// лежит прямо на белом (hero товара), передают [Colors.white].
  final Color? fallbackColor;

  /// Размер mock-картинки внутри заглушки (доля от меньшей стороны).
  /// По умолчанию 0.55 — мок заметно меньше блока, видно что это заглушка.
  final double fallbackScale;

  /// Если `true` — на пустом URL и при ошибке вместо mock-картинки
  /// рисуется чисто нейтральный цвет (без иконок/изображений).
  /// Полезно для full-screen фонов (header коллекции и т.п.), где
  /// бренд-mock товара выглядит как чужой кадр.
  final bool solidFallback;

  /// Шиммер только во время первой загрузки — пока бэк отдаёт байты.
  Widget _loadingShimmer() => dark
      ? SimpleShimmerBlack(borderRadius: 0)
      : SimpleShimmer(borderRadius: 0);

  /// Заглушка для пустого URL / ошибки загрузки. Два режима:
  /// - default: нейтральный фон + mock-картинка по центру (для плиток
  ///   товаров — видно что заглушка, не реальный товар).
  /// - solidFallback: только ровный нейтральный цвет, без mock-картинки
  ///   (для крупных фонов, где мок выглядит как чужое фото).
  Widget _fallback() {
    final bg = fallbackColor ?? _kFallbackBg;
    if (solidFallback) return ColoredBox(color: bg);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSide = constraints.biggest.shortestSide;
        final imgSide = maxSide * fallbackScale;
        return Container(
          color: bg,
          alignment: Alignment.center,
          child: Image.asset(
            _kFallbackAsset,
            width: imgSide,
            height: imgSide,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _fallback();

    return Image.network(
      url,
      fit: fit,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        // Картинка была в кэше — показываем сразу без анимации
        if (wasSynchronouslyLoaded) return child;

        // Первая загрузка: шиммер снизу, картинка плавно появляется сверху
        return Stack(
          fit: StackFit.expand,
          children: [
            _loadingShimmer(),
            AnimatedOpacity(
              opacity: frame == null ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: child,
            ),
          ],
        );
      },
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }
}

/// Обёртка для обратной совместимости — тёмный вариант с чёрным шиммером
class NetworkImageWidgetBlack extends NetworkImageWidget {
  const NetworkImageWidgetBlack({super.key, required super.url, super.fit})
      : super(dark: true);
}
