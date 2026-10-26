import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../app_pallete.dart';

/// Единый шит выбора одного значения из списка.
///
/// Вид один на всё приложение: белая панель со скруглением 30, чёрный
/// заголовок, круглый крестик, список в карточке с тонкой рамкой и
/// пунктирными разделителями, отметка выбранного — зелёное кольцо слева.
///
/// Используется и для коротких списков (сортировка), и для длинных
/// (регионы, города, филиалы) — во втором случае список прокручивается
/// внутри шита, а сам шит не вырастает выше 85% экрана.
///
/// Возвращает выбранный элемент или `null`, если шит закрыли.
Future<T?> showChoiceSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required String Function(T item) labelOf,
  T? selected,
  bool Function(T a, T b)? equals,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.white,
    barrierColor: const Color(0x40000000),
    // Иначе высота режется до 9/16 экрана и длинный список не помещается.
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (_) => _ChoiceSheet<T>(
      title: title,
      items: items,
      labelOf: labelOf,
      selected: selected,
      equals: equals,
    ),
  );
}

class _ChoiceSheet<T> extends StatelessWidget {
  const _ChoiceSheet({
    required this.title,
    required this.items,
    required this.labelOf,
    this.selected,
    this.equals,
  });

  final String title;
  final List<T> items;
  final String Function(T item) labelOf;
  final T? selected;
  final bool Function(T a, T b)? equals;

  bool _isSelected(T item) {
    if (selected == null) return false;
    return (equals ?? (a, b) => a == b)(item, selected as T);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () => Navigator.pop(context),
                    child: Container(
                      height: 32,
                      width: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F0F0),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF8A8A8A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hairlineBorder,
                      width: kHairlineWidth,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const DashedDivider(),
                    itemBuilder: (_, i) => _ChoiceRow(
                      label: labelOf(items[i]),
                      selected: _isSelected(items[i]),
                      onTap: () => Navigator.pop(context, items[i]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            ChoiceRadio(selected: selected),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Кольцо с точкой. Своё, а не `Radio`: у Material/Cupertino радио свои
/// отступы и анимация, из-за которых кружок не совпадал с макетом.
class ChoiceRadio extends StatelessWidget {
  const ChoiceRadio({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      width: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? mainColorLight : const Color(0xFFD9D9D9),
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                height: 10,
                width: 10,
                decoration: const BoxDecoration(
                  color: mainColorLight,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}

/// Горизонтальный пунктир между пунктами — штрих 3, пропуск 4.
class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 1,
        width: double.infinity,
        child: CustomPaint(painter: _DashedLinePainter()),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 3.0;
    const gap = 4.0;
    final paint = Paint()
      ..color = const Color(0xFFD9D9D9)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => false;
}
