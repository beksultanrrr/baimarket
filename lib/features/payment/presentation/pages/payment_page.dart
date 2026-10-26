import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/app_logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../live/presentation/widgets/live_shopping_scope.dart';
import '../../../order_success/data/models/order_success_args.dart';
import '../../data/models/payment_args.dart';
import '../cubit/payment_cubit.dart';
import '../widgets/bai_market_logo.dart';
import '../widgets/new_card_sheet.dart';
import '../widgets/payment_amount_card.dart';
import '../widgets/payment_card_selector.dart';
import '../widgets/payment_lang_pills.dart';
import '../widgets/payment_pay_button.dart';
import '../widgets/payment_terms_text.dart';
import '../widgets/select_card_sheet.dart';

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key, required this.args});
  final PaymentArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PaymentCubit(),
      child: _PaymentView(args: args),
    );
  }
}

class _PaymentView extends StatelessWidget {
  const _PaymentView({required this.args});
  final PaymentArgs args;

  Future<void> _openSelectCardSheet(BuildContext context) async {
    paymentLog.step('open select-card sheet');
    final cubit = context.read<PaymentCubit>();
    final result = await showSelectCardSheet(
      context: context,
      paymentCubit: cubit,
    );
    paymentLog.event('select-card sheet closed', result?.name ?? 'cancelled');
    if (!context.mounted) return;
    if (result == SelectCardResult.addNewCard) {
      paymentLog.step('open new-card sheet');
      final paid = await showNewCardSheet(
        context: context,
        paymentCubit: cubit,
      );
      paymentLog.event('new-card sheet closed', 'paid=$paid');
      if (paid == true && context.mounted) {
        _proceedToBankPayment(context);
      }
    }
  }

  void _onPayPressed(BuildContext context) {
    final rawState = context.read<PaymentCubit>().state;
    if (rawState is! PaymentReady) return;
    final state = rawState;
    paymentLog.step(
      'pay pressed',
      'selectedCardId=${state.selectedCardId}, '
          'savedCount=${state.cards.length}',
    );
    if (state.selectedCard == null) {
      paymentLog.warn('no card selected → opening sheet');
      _openSelectCardSheet(context);
      return;
    }
    _proceedToBankPayment(context);
  }

  /// Кладём выбранный brand карты в args и уходим в банковский WebView,
  /// если есть paymentUrl. Иначе (бэк не дал URL) — fallback на /order_success
  /// чтобы можно было прокликать flow без рабочей оплаты.
  void _proceedToBankPayment(BuildContext context) {
    final rawState = context.read<PaymentCubit>().state;
    if (rawState is! PaymentReady) return;
    final state = rawState;
    final enrichedArgs = args.copyWith(cardBrand: state.selectedCard?.brand);

    final url = args.paymentUrl;
    if (url != null && url.isNotEmpty) {
      paymentLog.nav(
        'push /payment_webview',
        'url="$url", brand=${state.selectedCard?.brand.name}',
      );
      liveAwarePush(context, '/payment_webview', extra: enrichedArgs);
      return;
    }

    paymentLog.warn('no paymentUrl → fallback to /order_success (mock-mode)');
    final successArgs = OrderSuccessArgs(
      orderId: args.orderId ??
          DateTime.now().millisecondsSinceEpoch.remainder(1000000),
      // Только товары: доставка идёт отдельной строкой, складывать их
      // на success-экране не наша забота.
      itemsTotal: args.itemsTotal ?? (args.amount - args.deliveryPrice),
      oldTotal: args.oldTotal,
      savings: args.savings ?? 0,
      ticketsEarned: args.ticketsEarned ?? 0,
      deliveryAddressLine: args.deliveryAddressLine,
      deliveryPostalCode: args.deliveryPostalCode,
      productImageUrls: args.productImageUrls,
      deliveryPrice: args.deliveryPrice,
      cardBrand: state.selectedCard?.brand,
    );
    liveAwarePush(context, '/order_success', extra: successArgs);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App bar (back + lang pills)
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(44, 44),
                      onPressed: () => context.pop(),
                      child: SvgPicture.asset(
                        'assets/icons/arrow_left.svg',
                        width: 24,
                        height: 24,
                      ),
                    ),
                    const Spacer(),
                    const PaymentLangPills(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: BaiMarketLogo(height: 40),
              ),
              const SizedBox(height: 24),
              PaymentAmountCard(
                amount: args.amount,
                itemsTotal: args.itemsTotal,
                deliveryPrice: args.deliveryPrice,
              ),
              const SizedBox(height: 14),
              BlocBuilder<PaymentCubit, PaymentState>(
                builder: (context, state) {
                  final s = state as PaymentReady;
                  return PaymentCardSelector(
                    card: s.selectedCard,
                    onTap: () => _openSelectCardSheet(context),
                  );
                },
              ),
              const SizedBox(height: 22),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: PaymentTermsText(),
              ),
              const SizedBox(height: 18),
              PaymentPayButton(
                label: l10n.payButton,
                onPressed: () => _onPayPressed(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
