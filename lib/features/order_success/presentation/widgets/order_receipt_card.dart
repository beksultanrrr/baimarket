import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../cards/presentation/widgets/brand_logo.dart';
import '../../../payment/presentation/widgets/tenge_format.dart';
import '../../data/models/order_success_args.dart';
import 'wavy_bottom_clipper.dart';

class OrderReceiptCard extends StatelessWidget {
  const OrderReceiptCard({super.key, required this.args});
  final OrderSuccessArgs args;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ClipPath(
      clipper: const WavyBottomClipper(scallopRadius: 7, topRadius: 0),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: _ReceiptBody(args: args, l10n: l10n),
      ),
    );
  }
}

class _ReceiptBody extends StatelessWidget {
  const _ReceiptBody({required this.args, required this.l10n});
  final OrderSuccessArgs args;
  final AppLocalizations l10n;

  /// Зачёркнутая цена ТОВАРОВ. `args.oldTotal` исторически считался вместе
  /// с доставкой (в него закладывалась константа 900), а `itemsTotal` — без
  /// неё, поэтому сравнивать их напрямую нельзя: «экономия» уехала бы на
  /// цену доставки. Приводим обе величины к одной базе — к товарам:
  /// до скидки товары стоили `itemsTotal + savings`.
  int? get _oldItemsTotal {
    if (args.savings > 0) return args.itemsTotal + args.savings;
    final old = args.oldTotal;
    if (old == null) return null;
    // Подстраховка на случай, если скидку не прокинули: снимаем доставку,
    // чтобы всё равно сравнивать товары с товарами.
    final oldItems = old - args.deliveryPrice;
    return oldItems > args.itemsTotal ? oldItems : null;
  }

  @override
  Widget build(BuildContext context) {
    // Разбивку показываем, только когда доставка реально стоит денег:
    // у старых заказов и у заказов без способа доставки deliveryPrice == 0.
    final deliveryPrice = args.deliveryPrice;
    final showDelivery = deliveryPrice > 0;
    // Трек-номер обычно ещё не известен (заказ только оформлен) — тогда
    // строки просто нет.
    final trackingNumber = args.trackingNumber?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            l10n.orderIdLabel(args.orderId.toString()),
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 18),
        _ProductsStrip(images: args.productImageUrls),
        const SizedBox(height: 18),
        _DeliverySummary(
          line: args.deliveryAddressLine,
          postalCode: args.deliveryPostalCode,
        ),
        const SizedBox(height: 20),
        const _DottedDivider(),
        const SizedBox(height: 18),
        _ReceiptRow(
          label: l10n.receiptItemsLabel,
          child: _PriceWithOld(current: args.itemsTotal, old: _oldItemsTotal),
        ),
        if (showDelivery) ...[
          const SizedBox(height: 10),
          _ReceiptRow(
            label: '${l10n.delivery}:',
            child: Text(
              formatTenge(deliveryPrice),
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        _ReceiptRow(
          label: l10n.receiptSavedLabel,
          child: Text(
            formatTenge(args.savings),
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2BB673),
            ),
          ),
        ),
        const SizedBox(height: 4),
        _ReceiptRow(
          label: l10n.receiptTicketsLabel,
          child: Text(
            '+${args.ticketsEarned}',
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFFEC3A3A),
            ),
          ),
        ),
        // Итог: товары + доставка. Сумму не пересчитываем по корзине —
        // обе величины приехали из заказа.
        if (showDelivery) ...[
          const SizedBox(height: 6),
          const _DottedDivider(),
          const SizedBox(height: 12),
          _ReceiptRow(
            label: '${l10n.amountToPay}:',
            labelStyle: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            child: Text(
              formatTenge(args.itemsTotal + deliveryPrice),
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        _ReceiptRow(
          label: l10n.receiptPaymentMethodLabel,
          child:
              args.cardBrand == null
                  ? const SizedBox.shrink()
                  : BrandLogo(brand: args.cardBrand!, size: const Size(48, 32)),
        ),
        if (trackingNumber.isNotEmpty) ...[
          const SizedBox(height: 10),
          _ReceiptRow(
            label: '${l10n.trackingNumberLabel}:',
            child: Text(
              trackingNumber,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProductsStrip extends StatelessWidget {
  const _ProductsStrip({required this.images});
  final List<String> images;

  @override
  Widget build(BuildContext context) {
    final list = images.isEmpty ? List.filled(3, '') : images;
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _ProductThumb(url: list[i]),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child:
          url.isEmpty
              ? const Icon(
                Icons.image_outlined,
                color: Color(0xFFC9C9C9),
                size: 36,
              )
              : Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder:
                    (_, __, ___) => const Icon(
                      Icons.image_outlined,
                      color: Color(0xFFC9C9C9),
                      size: 36,
                    ),
              ),
    );
  }
}

class _DeliverySummary extends StatelessWidget {
  const _DeliverySummary({this.line, this.postalCode});
  final String? line;
  final String? postalCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lines = <Widget>[];
    if (line != null && line!.isNotEmpty) {
      lines.add(
        Text(
          line!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Colors.black54,
          ),
        ),
      );
    }
    if (postalCode != null && postalCode!.isNotEmpty) {
      if (lines.isNotEmpty) lines.add(const SizedBox(height: 4));
      lines.add(
        Text(
          l10n.postalIndex(postalCode!),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
      );
    }
    if (lines.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: lines,
    );
  }
}

class _DottedDivider extends StatelessWidget {
  const _DottedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const dashGap = 4.0;
        final dashCount =
            (constraints.maxWidth / (dashWidth + dashGap)).floor();
        return Row(
          children: List.generate(
            dashCount,
            (_) => Padding(
              padding: const EdgeInsets.only(right: dashGap),
              child: Container(
                width: dashWidth,
                height: 1.5,
                color: const Color(0xFFD9D9D9),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.child, this.labelStyle});
  final String label;
  final Widget child;

  /// Переопределение стиля подписи — нужно итоговой строке «К оплате»,
  /// она темнее и жирнее остальных.
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            style: labelStyle ??
                const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8C8C8C),
                ),
          ),
        ),
        child,
      ],
    );
  }
}

class _PriceWithOld extends StatelessWidget {
  const _PriceWithOld({required this.current, required this.old});
  final int current;
  final int? old;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatTenge(current),
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFFEC3A3A),
          ),
        ),
        if (old != null && old != current) ...[
          const SizedBox(width: 8),
          Text(
            formatTenge(old!),
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8C8C8C),
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ],
    );
  }
}
