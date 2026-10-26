import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/app_pallete.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/kaspi_payment_cubit.dart';
import 'sheet_close_button.dart';
import 'tenge_format.dart';
import '../../../live/presentation/widgets/live_shopping_scope.dart';

/// Открывает шит оплаты заказа через Kaspi.
///
/// Показывает QR из [redirectUrl], кнопку «Оплатить» (открывает Kaspi)
/// и опрашивает статус заказа. Возвращает `true`, если заказ оплачен —
/// тогда вызывающий экран уходит на `/order_success`.
///
/// Сумма приходит готовой из заказа: [itemsTotal] — только товары,
/// [deliveryPrice] — доставка из корня заказа. Она зашита в платёжную ссылку
/// при создании заказа и после `retry()` не меняется, перечитывать заказ не надо.
Future<bool?> showKaspiPaymentSheet({
  required BuildContext context,
  required int orderId,
  required String redirectUrl,
  required int amount,
  int? itemsTotal,
  int deliveryPrice = 0,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    routeSettings: const RouteSettings(name: kLiveSheetRouteName),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    builder: (_) {
      return BlocProvider(
        create: (_) => KaspiPaymentCubit(
          orderId: orderId,
          redirectUrl: redirectUrl,
        ),
        child: _KaspiPaymentSheet(
          amount: amount,
          itemsTotal: itemsTotal,
          deliveryPrice: deliveryPrice,
        ),
      );
    },
  );
}

class _KaspiPaymentSheet extends StatelessWidget {
  const _KaspiPaymentSheet({
    required this.amount,
    this.itemsTotal,
    this.deliveryPrice = 0,
  });

  final int amount;

  /// Только товары. Если не передали — вычитаем доставку из общей суммы.
  final int? itemsTotal;

  /// Цена доставки из заказа. 0 — старый заказ, разбивку не показываем.
  final int deliveryPrice;

  int get _items => itemsTotal ?? (amount - deliveryPrice);

  /// К оплате = товары + доставка.
  int get _total => _items + deliveryPrice;

  Future<void> _openKaspi(BuildContext context, String url) async {
    paymentLog.step('kaspi: open redirectUrl', url);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<KaspiPaymentCubit, KaspiPaymentState>(
      listenWhen: (_, s) => s.status == KaspiStatus.paid,
      listener: (context, state) {
        paymentLog.event('kaspi: paid → close sheet (true)');
        Navigator.of(context).pop(true);
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.kaspiPayTitle,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      SheetCloseButton(
                        onPressed: () => Navigator.pop(context, false),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: BlocBuilder<KaspiPaymentCubit, KaspiPaymentState>(
                      builder: (context, state) {
                        return _buildBody(context, state, l10n);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    KaspiPaymentState state,
    AppLocalizations l10n,
  ) {
    // Провал / истёкшая ссылка — экран повтора оплаты.
    if (state.status == KaspiStatus.failed ||
        state.status == KaspiStatus.expired) {
      final message = state.status == KaspiStatus.expired
          ? l10n.kaspiLinkExpired
          : l10n.kaspiPaymentFailed;
      return Column(
        children: [
          const SizedBox(height: 12),
          const Icon(Icons.error_outline, size: 56, color: Color(0xFFE4002B)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          // Сумма нужна и здесь: повтор оплаты берёт новую ссылку, но цена
          // доставки зашита в заказ и не пересчитывается.
          _amountBlock(l10n),
          const SizedBox(height: 20),
          _PrimaryButton(
            label: l10n.kaspiPayAgain,
            onPressed: () => context.read<KaspiPaymentCubit>().retry(),
          ),
        ],
      );
    }

    final url = state.redirectUrl;
    final isRetrying = state.status == KaspiStatus.retrying;

    return Column(
      children: [
        const SizedBox(height: 4),
        _amountBlock(l10n),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: (isRetrying || url == null || url.isEmpty)
              ? const SizedBox(
                  width: 220,
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                )
              : QrImageView(
                  data: url,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.kaspiScanOrPay,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6E6E6E),
          ),
        ),
        const SizedBox(height: 20),
        _PrimaryButton(
          label: l10n.payButton,
          color: const Color(0xFFE4002B),
          onPressed: (url == null || url.isEmpty)
              ? null
              : () => _openKaspi(context, url),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.kaspiWaitingPayment,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6E6E6E),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Разбивка «Товары / Доставка / К оплате». Если доставки в заказе нет
  /// ([deliveryPrice] == 0, старые заказы) — одна строка, как раньше.
  Widget _amountBlock(AppLocalizations l10n) {
    if (deliveryPrice <= 0) {
      return Text(
        l10n.kaspiAmountToPay(formatTenge(_total)),
        style: const TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _amountRow(l10n.items, formatTenge(_items)),
          const SizedBox(height: 10),
          _amountRow(l10n.delivery, formatTenge(deliveryPrice)),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEDEDED)),
          const SizedBox(height: 12),
          _amountRow(l10n.amountToPay, formatTenge(_total), strong: true),
        ],
      ),
    );
  }

  Widget _amountRow(String label, String value, {bool strong = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: strong ? 15 : 14,
              fontWeight: strong ? FontWeight.w600 : FontWeight.w500,
              color: strong ? Colors.black : const Color(0xFF6E6E6E),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: strong ? 18 : 15,
            fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.color = mainColorLight,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.45),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
