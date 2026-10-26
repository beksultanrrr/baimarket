import 'package:bai_market/core/app_pallete.dart';
import 'package:flutter/material.dart';

/// Ряд из [length] точек PIN; первые [filled] — заполнены.
class PinDots extends StatelessWidget {
  const PinDots({super.key, required this.length, required this.filled});

  final int length;
  final int filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final isFilled = i < filled;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? mainColorLight : const Color(0xFFD9D9D9),
          ),
        );
      }),
    );
  }
}

/// Цифровая клавиатура 3×4: 1–9, пусто · 0 · Backspace.
class PinKeypad extends StatelessWidget {
  const PinKeypad({super.key, required this.onDigit, required this.onBackspace});

  final void Function(String digit) onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    Widget digit(String d) => _KeypadButton(
          onTap: () => onDigit(d),
          child: Text(
            d,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w400,
              color: Color(0xFF17181C),
              fontFamily: 'Gilroy',
            ),
          ),
        );

    Widget row(List<Widget> children) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: children),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          row([digit('1'), digit('2'), digit('3')]),
          row([digit('4'), digit('5'), digit('6')]),
          row([digit('7'), digit('8'), digit('9')]),
          row([
            const _KeypadButton(child: SizedBox.shrink()),
            digit('0'),
            _KeypadButton(
              onTap: onBackspace,
              child: const Icon(Icons.backspace_outlined, size: 26, color: Color(0xFF17181C)),
            ),
          ]),
        ],
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const double size = 72;
    if (onTap == null) return const SizedBox(width: size, height: size);
    return SizedBox(
      width: size,
      height: size,
      child: InkResponse(
        onTap: onTap,
        radius: 40,
        child: Center(child: child),
      ),
    );
  }
}
