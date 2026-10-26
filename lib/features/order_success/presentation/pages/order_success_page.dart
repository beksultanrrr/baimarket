import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../live/presentation/widgets/live_shopping_scope.dart';
import '../../../payment/presentation/widgets/payment_pay_button.dart';
import '../../data/models/order_success_args.dart';
import '../widgets/order_receipt_card.dart';

class OrderSuccessPage extends StatefulWidget {
  const OrderSuccessPage({super.key, required this.args});
  final OrderSuccessArgs args;

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage> {
  @override
  void initState() {
    super.initState();
    // Все четыре пути оплаты (наличные, Kaspi, webview, фолбэк) сходятся сюда,
    // поэтому один хук закрывает их все. На сервере корзина уже удалена —
    // её позиции переехали в заказ.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CartCubit>().refreshAfterOrder();
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black.withValues(alpha: 0.5)),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  left: 12,
                  top: 12,
                  child: _CloseButton(
                    // Заказ оформлен — возвращаемся туда, откуда пришли:
                    // внутри эфира это сам эфир, снаружи — главная.
                    onTap: () => liveAwareDismiss(context),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 64, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        l10n.orderAcceptedTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 26,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Center(
                            child: SizedBox(
                              width: 300,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    top: 0,
                                    left: -25,
                                    right: -25,
                                    child: SvgPicture.asset(
                                      'assets/icons/ticket_bg.svg',
                                      width: 350,
                                      height: 50,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 25),
                                    child: OrderReceiptCard(args: args),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: SizedBox(
                          width: 300,
                          child: PaymentPayButton(
                            label: l10n.viewOrderStatus,
                            // Осознанный выход из эфира: покупка уже
                            // завершена, статус заказа — отдельный экран.
                            onPressed: () => liveAwareGo(context, '/orders'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
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

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(40, 40),
      onPressed: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}
