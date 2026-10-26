import 'package:bai_market/core/app_pallete.dart';
import 'package:bai_market/core/auth/app_lock.dart';
import 'package:bai_market/core/auth/pending_action.dart';
import 'package:bai_market/core/pin_storage.dart';
import 'package:bai_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../widgets/pin_keypad.dart';
import 'package:bai_market/core/routing/app_routing.dart';
import 'package:bai_market/features/profile/presentation/cubit/current_user_cubit.dart';

/// Создание PIN сразу после первого входа по OTP: ввод → подтверждение.
class PinCreatePage extends StatefulWidget {
  const PinCreatePage({super.key});

  @override
  State<PinCreatePage> createState() => _PinCreatePageState();
}

class _PinCreatePageState extends State<PinCreatePage> {
  static const int _pinLength = 4;

  String _firstPin = '';
  String _pin = '';
  bool _confirming = false;
  bool _mismatch = false;
  bool _saving = false;

  void _onDigit(String d) {
    if (_saving || _pin.length >= _pinLength) return;
    setState(() {
      _pin += d;
      _mismatch = false;
    });
    if (_pin.length == _pinLength) {
      HapticFeedback.selectionClick();
      _onCompleted();
    }
  }

  void _onBackspace() {
    if (_saving || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _onCompleted() async {
    if (!_confirming) {
      // Первый ввод — переходим к подтверждению.
      setState(() {
        _firstPin = _pin;
        _pin = '';
        _confirming = true;
      });
      return;
    }

    // Подтверждение.
    if (_pin == _firstPin) {
      setState(() => _saving = true);
      await setPin(_pin);
      AppLock.unlock();
      // Как и в otp_page: корзина грузится до отложенного «Купить».
      if (mounted) context.read<CartCubit>().ensureLoaded();
      if (mounted) context.read<CurrentUserCubit>().reload();
      PendingAuthAction.runAndClear();
      // Как в otp_page: если человек шёл на защищённый маршрут, доводим его.
      if (mounted) context.go(takePendingProtectedLocation() ?? '/main');
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _mismatch = true;
        _pin = '';
        _firstPin = '';
        _confirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 72),

            // Заголовок
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _confirming ? l10n.confirmPinTitle : l10n.createPinTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: mainColorLight,
                  fontFamily: 'Gilroy',
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Ошибка несовпадения
            SizedBox(
              height: 20,
              child: _mismatch
                  ? Text(
                      l10n.pinMismatch,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFE53935),
                        fontFamily: 'Gilroy',
                      ),
                    )
                  : null,
            ),

            const SizedBox(height: 20),

            PinDots(length: _pinLength, filled: _pin.length),

            const Spacer(flex: 2),

            PinKeypad(onDigit: _onDigit, onBackspace: _onBackspace),

            const Spacer(flex: 2),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
