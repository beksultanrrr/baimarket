import 'package:flutter/material.dart';

/// Кружок в горизонтальном ряду над лентой эфиров.
///
/// Изначально рисовал «активный эфир», теперь им же выложен ряд сториз:
/// геометрия и цвета совпадали один в один, поэтому вместо второго такого же
/// виджета добавлены три необязательных параметра.
class StreamsAvatarItem extends StatelessWidget {
  const StreamsAvatarItem({
    super.key,
    required this.imageUrl,
    required this.name,
    this.isActive = false,
    this.ringColor,
    this.ringWidth = 2,
    this.overlay,
    this.onTap,
  });

  final String imageUrl;
  final String name;
  final bool isActive;

  /// Цвет кольца. По умолчанию — как раньше: зелёное у активного, полупрозрачное
  /// белое у остальных.
  final Color? ringColor;

  final double ringWidth;

  /// Что нарисовать поверх аватара (например, значок «в эфире»).
  final Widget? overlay;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final border = ringColor ??
        (isActive
            ? const Color(0xFF71CD32)
            : Colors.white.withValues(alpha: 0.25));

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: border, width: ringWidth),
              ),
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Пустой URL раньше «работал» только потому, что
                    // Image.network('') случайно падал в errorBuilder.
                    if (imageUrl.isEmpty)
                      const _AvatarFallback()
                    else
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _AvatarFallback(),
                      ),
                    if (overlay != null) overlay!,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2A2A2A),
      child: const Icon(Icons.person, color: Colors.white54, size: 28),
    );
  }
}
