import 'package:bai_market/core/app_pallete.dart';
import 'package:bai_market/core/auth/app_lock.dart';
import 'package:bai_market/core/auth/sign_out.dart';
import 'package:bai_market/core/pin_storage.dart';
import 'package:bai_market/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../widgets/pin_keypad.dart';

/// Экран блокировки для вернувшегося авторизованного пользователя:
/// приветствие по имени, 4-значный PIN и цифровая клавиатура.
class PinLockPage extends StatefulWidget {
  const PinLockPage({super.key});

  @override
  State<PinLockPage> createState() => _PinLockPageState();
}

class _PinLockPageState extends State<PinLockPage> {
  static const int _pinLength = 4;
  String _pin = '';
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    // Подтягиваем профиль, чтобы показать имя в приветствии.
    final cubit = context.read<ProfileCubit>();
    if (cubit.state is! ProfileGot) {
      cubit.getProfileData();
    }
  }

  void _onDigit(String d) {
    if (_checking || _pin.length >= _pinLength) return;
    setState(() => _pin += d);
    if (_pin.length == _pinLength) {
      HapticFeedback.selectionClick();
      _onCompleted(_pin);
    }
  }

  void _onBackspace() {
    if (_checking || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _onCompleted(String pin) async {
    setState(() => _checking = true);
    final ok = await verifyPin(pin);
    if (!mounted) return;
    if (ok) {
      AppLock.unlock();
      context.go('/main');
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _pin = '';
        _checking = false;
      });
      _showWrongPinToast();
    }
  }

  void _showWrongPinToast() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.wrongPin),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const greetingStyle = TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: mainColorLight, fontFamily: 'Gilroy', height: 1.3);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 56),

            // Приветствие
            Text(l10n.greeting, textAlign: TextAlign.center, style: greetingStyle),
            BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, state) {
                final name = state is ProfileGot ? (state.profile.firstName ?? '') : '';
                if (name.isEmpty) return const SizedBox.shrink();
                return Text(name, textAlign: TextAlign.center, style: greetingStyle);
              },
            ),

            const Spacer(flex: 1),

            PinDots(length: _pinLength, filled: _pin.length),
            const Spacer(flex: 1),

            // Клавиатура
            PinKeypad(onDigit: _onDigit, onBackspace: _onBackspace),

            const Spacer(flex: 2),

            const SizedBox(height: 18),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => signOutAndCleanup(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 24),
                child: Text(l10n.cannotLogin, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: mainColorLight, fontFamily: 'Gilroy')),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
