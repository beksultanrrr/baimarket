import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/app_pallete.dart';
import '../../../../core/urls.dart';
import '../../../../core/utils/order_status_utils.dart';
import '../../../../core/widgets/show_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/presentation/widgets/order_filter.dart';
import '../../../payment/data/models/payment_args.dart';

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
    // Трек-номер приходит строкой вида "AP081184854KZ"; у только что созданного
    // заказа его ещё нет. Пробелы срезаем — из номера собирается ссылка на post.kz.
    final tracking = order.trackingNumber?.trim() ?? '';

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
            _PayButton(order: order),
          ],
          if (tracking.isNotEmpty) ...[
            const SizedBox(height: 18),
            _TrackingBlock(trackingNumber: tracking),
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
      case 'PROCESSING':
      case 'ASSEMBLING':
        return mainColorDark;
      // PICKUP — посылка уже доехала и ждёт в отделении Казпочты, а не едет.
      // Красим как доставленный: покупателю остаётся только забрать.
      case 'PICKUP':
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
        return l10n.orderInTransitMessage;
      // PICKUP больше не «в пути»: это «ждёт в отделении Казпочты».
      case 'PICKUP':
        return l10n.orderStatusPickupKazpostMessage;
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
  const _PayButton({required this.order});
  final OrderModel order;

  /// Полные аргументы повторной оплаты. Раньше в `extra` уезжала одна строка
  /// URL, и экран оплаты рисовал «0 ₸»: суммы взять было неоткуда.
  /// Считать ничего не надо — обе цифры уже лежат в заказе,
  /// `totalPrice` это ТОЛЬКО товары, `deliveryPrice` — корень заказа.
  PaymentArgs _paymentArgs() {
    final info = order.deliveryInfo ?? const <String, dynamic>{};
    final street = (info['deliveryAddress'] as String?)?.trim() ?? '';
    final houseNumber = info['houseNumber']?.toString().trim() ?? '';
    final addressLine =
        [street, houseNumber].where((part) => part.isNotEmpty).join(', ');
    // Пути к фото идут без `imgUrl` — префикс добавляет уже сам экран.
    final productImages = <String>[];
    for (final item in order.cartItems) {
      final urls = item.model.photoUrls;
      if (urls != null && urls.isNotEmpty) productImages.add(urls.first);
    }
    return PaymentArgs(
      amount: order.totalPrice + order.deliveryPrice,
      paymentUrl: order.paymentUrl,
      itemsTotal: order.totalPrice,
      deliveryPrice: order.deliveryPrice,
      deliveryMethod: info['deliveryMethod']?.toString(),
      orderId: order.id,
      deliveryAddressLine: addressLine.isEmpty ? null : addressLine,
      deliveryPostalCode: info['postalCode']?.toString(),
      productImageUrls: productImages,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => context.push('/payment', extra: _paymentArgs()),
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

/// Трек-номер посылки: копирование по тапу и переход на страницу Казпочты.
/// Показывается, только когда бэк уже присвоил номер (`trackingNumber != null`).
class _TrackingBlock extends StatelessWidget {
  const _TrackingBlock({required this.trackingNumber});

  final String trackingNumber;

  Future<void> _copy(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: trackingNumber));
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.trackingNumberCopied)),
    );
  }

  Future<void> _openTracking(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse(kazpostTrackingUrl(trackingNumber));
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (ok) return;
    } catch (_) {
      // Открывать нечем — падаем в снекбар ниже, номер всё равно можно
      // скопировать и вбить на post.kz руками.
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.failedToOpen('post.kz')),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.trackingNumberLabel,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFFB8B8B8),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _copy(context),
                  child: Text(
                    trackingNumber,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(36, 36),
                onPressed: () => _copy(context),
                child: const Icon(
                  Icons.copy_rounded,
                  size: 20,
                  color: mainColorDark,
                ),
              ),
            ],
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 32),
            alignment: Alignment.centerLeft,
            onPressed: () => _openTracking(context),
            child: Text(
              l10n.trackOnKazpost,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: mainColorDark,
              ),
            ),
          ),
        ],
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
                                color: const Color(0xFFD4F4C1),
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
