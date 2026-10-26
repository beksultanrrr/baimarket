import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../cubit/payment_cubit.dart';
import 'new_card_form_fields.dart';
import 'payment_pay_button.dart';
import 'payment_terms_text.dart';
import 'payment_warning_box.dart';
import 'save_card_switch.dart';
import 'sheet_close_button.dart';
import '../../../live/presentation/widgets/live_shopping_scope.dart';

/// Открывает шит ввода новой карты. Возвращает `true`, если пользователь
/// нажал "Оплатить" (карта валидна), иначе `null`.
Future<bool?> showNewCardSheet({
  required BuildContext context,
  required PaymentCubit paymentCubit,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    routeSettings: const RouteSettings(name: kLiveSheetRouteName),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      return BlocProvider.value(
        value: paymentCubit,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: const _NewCardSheet(),
        ),
      );
    },
  );
}

class _NewCardSheet extends StatefulWidget {
  const _NewCardSheet();

  @override
  State<_NewCardSheet> createState() => _NewCardSheetState();
}

class _NewCardSheetState extends State<_NewCardSheet> {
  final _numberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  bool _saveCard = true;

  @override
  void initState() {
    super.initState();
    for (final c in [_numberCtrl, _expiryCtrl, _cvvCtrl]) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    for (final c in [_numberCtrl, _expiryCtrl, _cvvCtrl]) {
      c.removeListener(_onChanged);
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  bool get _canPay {
    final digits = _numberCtrl.text.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 16 &&
        _expiryCtrl.text.length >= 5 &&
        _cvvCtrl.text.length == 3;
  }

  void _onPayPressed() {
    if (!_canPay) return;
    if (_saveCard) {
      context.read<PaymentCubit>().addCardFromInput(rawNumber: _numberCtrl.text);
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.enterCardDataTitle,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
                SheetCloseButton(onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 18),
            NewCardNumberField(controller: _numberCtrl),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: NewCardExpiryField(controller: _expiryCtrl)),
                const SizedBox(width: 12),
                Expanded(child: NewCardCvvField(controller: _cvvCtrl)),
              ],
            ),
            const SizedBox(height: 18),
            StatefulBuilder(
              builder: (context, setLocal) => SaveCardSwitch(
                value: _saveCard,
                onChanged: (v) => setLocal(() => _saveCard = v),
              ),
            ),
            const SizedBox(height: 16),
            const PaymentWarningBox(),
            const SizedBox(height: 18),
            const PaymentTermsText(),
            const SizedBox(height: 18),
            PaymentPayButton(
              label: l10n.payButton,
              onPressed: _canPay ? _onPayPressed : null,
            ),
          ],
        ),
      ),
    );
  }
}
