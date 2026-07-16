import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_pallete.dart';
import '../../../../core/urls.dart';
import '../../../../core/utils/order_status_utils.dart';
import '../../../../core/widgets/show_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/presentation/widgets/order_filter.dart';

class OrderStatusCard extends StatelessWidget {
  const OrderStatusCard({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filter = orderFilterForStatus(order.status);
    final statusText = getOrderStatusText(context, order.status);
    final statusColor = _statusHeadlineColor(order.status);
    final message = _statusMessage(context, order.status, filter);
    final showPayCta = order.status == 'PAYMENT_PENDING' &&
        (order.paymentUrl ?? '').isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            statusText,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: statusColor,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.orderId(order.id.toString()),
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          if (showPayCta) ...[
            const SizedBox(height: 18),
            _PayButton(url: order.paymentUrl!),
          ],
          if (order.cartItems.isNotEmpty) ...[
            const SizedBox(height: 18),
            _ProductRow(order: order),
          ],
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFFB8B8B8),
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusHeadlineColor(String? status) {
    switch (status) {
      case 'PAYMENT_PENDING':
        return const Color(0xFF2B8BE8);
      case 'WAY':
      case 'PICKUP':
      case 'PROCESSING':
      case 'ASSEMBLING':
        return mainColorDark;
      case 'DELIVERED':
        return const Color(0xFF5AC47D);
      case 'CANCELED':
      case 'ABANDONED':
      case 'PAYMENT_FAILED':
        return const Color(0xFFEE6A5A);
      default:
        return Colors.black;
    }
  }

  String? _statusMessage(
    BuildContext context,
    String? status,
    OrderFilter filter,
  ) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'PAYMENT_PENDING':
      case 'PROCESSING':
      case 'ASSEMBLING':
        return l10n.orderProcessingMessage;
      case 'WAY':
      case 'PICKUP':
        return l10n.orderInTransitMessage;
      case 'DELIVERED':
        return l10n.orderDeliveredMessage;
      case 'CANCELED':
      case 'ABANDONED':
      case 'PAYMENT_FAILED':
        return l10n.orderReturnMessage;
    }
    return null;
  }
}

class _PayButton extends StatelessWidget {
  const _PayButton({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => context.push('/payment', extra: url),
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: mainColorLight,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          l10n.goToPayment,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: order.cartItems.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = order.cartItems[index];
          final product = item.model;
          final photo = (product.photoUrls?.isNotEmpty ?? false)
              ? '$imgUrl${product.photoUrls!.first}'
              : null;
          final hasDiscount = (product.oldPrice ?? 0) > (product.price ?? 0);

          return CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => context.push('/product/${product.id}'),
            child: Container(
              width: 220,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: lightGray,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 80,
                      width: 72,
                      child: photo == null
                          ? const SizedBox()
                          : NetworkImageWidget(url: photo),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F7F2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${product.price ?? 0}₸',
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: mainColorDark,
                                ),
                              ),
                            ),
                            if (hasDiscount) ...[
                              const SizedBox(width: 6),
                              Text(
                                '${product.oldPrice}₸',
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFFB8B8B8),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
