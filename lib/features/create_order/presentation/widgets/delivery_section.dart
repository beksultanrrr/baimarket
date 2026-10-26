import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/app_pallete.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../payment/presentation/widgets/tenge_format.dart';
import '../../data/models/delivery_quote.dart';
import 'section_card.dart';

/// Блок доставки: строка выбранного адреса, поля адреса и выбор способа.
///
/// Самовывоза больше нет, поэтому сегмента «Курьером/Самовывоз» здесь тоже
/// нет — вместо него два способа Казпочты, их рисует
/// [DeliveryMethodSelector].
class DeliverySection extends StatelessWidget {
  const DeliverySection({super.key, required this.row, this.children = const <Widget>[]});

  /// Строка сохранённого адреса (см. [DeliveryEntryRow]).
  final Widget row;

  /// Поля индекса, улицы, дома и селектор способа — идут под строкой адреса,
  /// каждый через один отступ.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row,
          for (final child in children) ...[const SizedBox(height: 16), child],
        ],
      ),
    );
  }
}

/// Выбор способа доставки: до отделения Казпочты или до двери.
///
/// Бэк присылает ровно два варианта в порядке BRANCH, DOOR, поэтому веток на
/// пустой или одиночный список нет. Признака «по умолчанию» контракт не даёт —
/// пока покупатель не ткнул, [selected] равен `null`.
class DeliveryMethodSelector extends StatelessWidget {
  const DeliveryMethodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.branchPrice,
    this.doorPrice,
    this.statusText,
    this.onRetry,
  });

  final DeliveryMethod? selected;
  final ValueChanged<DeliveryMethod> onChanged;

  /// Цены из котировки. `null` — расчёта ещё нет (индекс не дописан, запрос
  /// в пути или упал), тогда вместо цены показываем [statusText] под списком.
  final int? branchPrice;
  final int? doorPrice;

  /// Подсказка вместо цен: «введите индекс», «рассчитываем…», ошибка расчёта.
  final String? statusText;

  /// Повтор расчёта. Задаётся только на ошибке — рядом с [statusText]
  /// появляется «Попробовать снова».
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MethodTile(
          title: l10n.deliveryMethodBranch,
          hint: l10n.deliveryMethodBranchHint,
          price: branchPrice,
          isSelected: selected == DeliveryMethod.branch,
          onTap: () => onChanged(DeliveryMethod.branch),
        ),
        const SizedBox(height: 8),
        _MethodTile(
          title: l10n.deliveryMethodDoor,
          hint: l10n.deliveryMethodDoorHint,
          price: doorPrice,
          isSelected: selected == DeliveryMethod.door,
          onTap: () => onChanged(DeliveryMethod.door),
        ),
        if (statusText != null) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  statusText!,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: onRetry != null ? const Color(0xFFFF3B47) : const Color(0xFF8A8A8A),
                    height: 1.3,
                  ),
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onRetry,
                  child: Text(
                    l10n.tryAgain,
                    style: const TextStyle(fontFamily: 'Gilroy', fontSize: 13, fontWeight: FontWeight.w700, color: mainColorDark),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.title, required this.hint, required this.price, required this.isSelected, required this.onTap});

  final String title;
  final String hint;
  final int? price;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF3FBEE) : lightGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? mainColorLight : hairlineBorder, width: kHairlineWidth),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Radio(isSelected: isSelected),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontFamily: 'Gilroy', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: const TextStyle(fontFamily: 'Gilroy', fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF8A8A8A), height: 1.3),
                  ),
                ],
              ),
            ),
            // Цена появляется только после расчёта: до него подсказка одна на
            // оба варианта и висит под списком.
            if (price != null) ...[
              const SizedBox(width: 8),
              Text(
                formatTenge(price!),
                style: const TextStyle(fontFamily: 'Gilroy', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.isSelected});
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      width: 22,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? mainColorLight : Colors.white,
        border: Border.all(color: isSelected ? mainColorLight : const Color(0xFFD9D9D9), width: 1.5),
      ),
      child: isSelected ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
    );
  }
}

class DeliveryEntryRow extends StatelessWidget {
  const DeliveryEntryRow({super.key, required this.iconAsset, required this.title, required this.onTap, this.subtitle, this.actionLabel, this.actionColor});

  final String iconAsset;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final Color? actionColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(color: const Color(0xFFDCF3CC), borderRadius: BorderRadius.circular(10)),
            child: Center(child: SvgPicture.asset(iconAsset, height: 24, width: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontFamily: 'Gilroy', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(fontFamily: 'Gilroy', fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF8A8A8A), height: 1.3),
                  ),
                ],
                if (actionLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    actionLabel!,
                    style: TextStyle(fontFamily: 'Gilroy', fontSize: 14, fontWeight: FontWeight.w600, color: actionColor ?? const Color(0xFF1A8FFF)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: Colors.black38, size: 24),
        ],
      ),
    );
  }
}
