import 'package:flutter/material.dart';

import '../../../../core/app_pallete.dart';
import 'section_card.dart';

enum PaymentMethod { card, kaspi, halyk, cash }

class PaymentMethodsSection extends StatelessWidget {
  const PaymentMethodsSection({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Способы оплаты',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6E6E6E),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _MethodCard(
                  isSelected: selected == PaymentMethod.kaspi,
                  onTap: () => onChanged(PaymentMethod.kaspi),
                  label: 'Kaspi',
                  icon: const Icon(
                    Icons.qr_code_2_rounded,
                    size: 28,
                    color: Color(0xFFE4002B),
                  ),
                ),
                const SizedBox(width: 10),
                _MethodCard(
                  isSelected: selected == PaymentMethod.cash,
                  onTap: () => onChanged(PaymentMethod.cash),
                  label: 'Наличными',
                  icon: const Icon(
                    Icons.payments_outlined,
                    size: 28,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.isSelected,
    required this.onTap,
    required this.label,
    required this.icon,
  });

  final bool isSelected;
  final VoidCallback onTap;
  final String label;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 132,
        decoration: BoxDecoration(
          color: lightGray,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? mainColorLight : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
