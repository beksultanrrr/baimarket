import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/app_pallete.dart';
import '../../../../core/urls.dart';
import '../../../../core/widgets/show_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/order_model.dart';
import 'order_filter.dart';
import 'order_status_tag.dart';
import 'payment_status_chip.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.onLeaveReview,
  });

  final OrderModel order;
  final VoidCallback onTap;
  final VoidCallback? onLeaveReview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filter = orderFilterForStatus(order.status);
    final address =
        order.deliveryInfo?['deliveryAddress'] as String? ?? l10n.noData;
    final showReview =
        filter == OrderFilter.completed && onLeaveReview != null;
    final isPaid = order.status != 'PAYMENT_PENDING' &&
        order.status != 'PAYMENT_FAILED' &&
        order.status != 'ABANDONED';

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                OrderStatusTag(status: order.status),
                const Spacer(),
                PaymentStatusChip(isPaid: isPaid, price: order.totalPrice),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              l10n.orderId(order.id.toString()),
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              address,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFFB8B8B8),
                height: 1.4,
              ),
            ),
            if (order.cartItems.isNotEmpty) ...[
              const SizedBox(height: 14),
              _ProductThumbStrip(items: order.cartItems),
            ],
            if (showReview) ...[
              const SizedBox(height: 16),
              _ReviewButton(onPressed: onLeaveReview!),
            ],
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
          final url = (photos != null && photos.isNotEmpty)
              ? '$imgUrl${photos.first}'
              : null;
          return Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: lightGray,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: url == null
                ? const SizedBox()
                : NetworkImageWidget(url: url),
          );
        },
      ),
    );
  }
}

class _ReviewButton extends StatelessWidget {
  const _ReviewButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFE6F7F2),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          l10n.orderLeaveReview,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: mainColorDark,
          ),
        ),
      ),
    );
  }
}
