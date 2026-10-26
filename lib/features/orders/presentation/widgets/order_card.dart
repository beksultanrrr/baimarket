import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/app_pallete.dart';
import '../../../../core/urls.dart';
import '../../../../core/widgets/show_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/order_model.dart';
// TODO(reviews): нужен только кнопке отзыва — вернуть вместе с ней.
// import 'order_filter.dart';
import 'order_status_tag.dart';
import 'payment_status_chip.dart';

/// Адрес и индекс в карточке — `#000000` при 50% (в записи Figma `#00000080`).
const Color _addressColor = Color(0x80000000);

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    // TODO(reviews): отзывы временно отключены целиком.
    // this.onLeaveReview,
  });

  final OrderModel order;
  final VoidCallback onTap;
  // TODO(reviews): отзывы временно отключены целиком.
  // final VoidCallback? onLeaveReview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // TODO(reviews): `filter` нужен был только кнопке отзыва — вернуть с ней.
    // final filter = orderFilterForStatus(order.status);
    final info = order.deliveryInfo ?? const <String, dynamic>{};
    // Улица и дом лежат в РАЗНЫХ полях: `deliveryAddress` — только улица,
    // `houseNumber` — дом и квартира одной строкой. У старых заказов дома нет,
    // там весь адрес целиком в `deliveryAddress` — фолбэк на прежний вид.
    final street = (info['deliveryAddress'] as String?)?.trim() ?? '';
    final houseNumber = info['houseNumber']?.toString().trim() ?? '';
    final addressLine =
        [street, houseNumber].where((part) => part.isNotEmpty).join(', ');
    final address = addressLine.isEmpty ? l10n.noData : addressLine;
    // Индекс в макете идёт отдельной строкой под адресом. Ключ тот же, что
    // читает `order_address_card.dart`; у старых заказов его может не быть.
    final postalCode = info['postalCode']?.toString();
    // TODO(reviews): отзывы временно отключены целиком.
    // final showReview =
    //     filter == OrderFilter.completed && onLeaveReview != null;
    final isPaid = order.status != 'PAYMENT_PENDING' && order.status != 'PAYMENT_FAILED' && order.status != 'ABANDONED';

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: hairlineBorder, width: kHairlineWidth),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                OrderStatusTag(status: order.status),
                const Spacer(),
                // В чипе — сумма, которую покупатель реально платит:
                // totalPrice это ТОЛЬКО товары, доставка лежит рядом в корне.
                PaymentStatusChip(
                  isPaid: isPaid,
                  price: order.totalPrice + order.deliveryPrice,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              l10n.orderId(order.id.toString()),
              style: const TextStyle(fontFamily: 'Gilroy', fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
            ),
            const SizedBox(height: 8),
            // Figma: Gilroy 400, 12px, line-height 100%, #000000 @ 50%.
            // Во Flutter альфа идёт ПЕРВОЙ: 0x80000000, а не 0x00000080
            // (последнее — полностью прозрачный, текст пропадает).
            Text(
              address,
              style: const TextStyle(fontFamily: 'Gilroy', fontSize: 12, fontWeight: FontWeight.w400, color: _addressColor, height: 1.2),
            ),
            if (postalCode != null && postalCode.isNotEmpty)
              Text(
                l10n.postalIndex(postalCode),
                style: const TextStyle(fontFamily: 'Gilroy', fontSize: 12, fontWeight: FontWeight.w400, color: _addressColor, height: 1.2),
              ),
            if (order.cartItems.isNotEmpty) ...[const SizedBox(height: 14), _ProductThumbStrip(items: order.cartItems)],
            // TODO(reviews): отзывы временно отключены целиком.
            // if (showReview) ...[
            //   const SizedBox(height: 16),
            //   _ReviewButton(onPressed: onLeaveReview!),
            // ],
          ],
        ),
      ),
    );
  }
}

class _ProductThumbStrip extends StatelessWidget {
  const _ProductThumbStrip({required this.items});

  final List items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final photos = items[index].model.photoUrls as List<String>?;
          final url = (photos != null && photos.isNotEmpty) ? '$imgUrl${photos.first}' : null;
          return Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(color: lightGray, borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: url == null ? const SizedBox() : NetworkImageWidget(url: url),
          );
        },
      ),
    );
  }
}

// TODO(reviews): отзывы временно отключены целиком.
// class _ReviewButton extends StatelessWidget {
//   const _ReviewButton({required this.onPressed});
//
//   final VoidCallback onPressed;
//
//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     return CupertinoButton(
//       padding: EdgeInsets.zero,
//       onPressed: onPressed,
//       child: Container(
//         height: 52,
//         width: double.infinity,
//         decoration: BoxDecoration(
//           color: const Color(0xFFD4F4C1),
//           borderRadius: BorderRadius.circular(14),
//         ),
//         alignment: Alignment.center,
//         child: Text(
//           l10n.orderLeaveReview,
//           style: const TextStyle(
//             fontFamily: 'Gilroy',
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             color: mainColorDark,
//           ),
//         ),
//       ),
//     );
//   }
// }
