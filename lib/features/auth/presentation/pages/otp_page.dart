import 'dart:async';

import 'package:bai_market/core/app_pallete.dart';
import 'package:bai_market/core/auth/app_lock.dart';
import 'package:bai_market/core/auth/pending_action.dart';
import 'package:bai_market/core/auth/sign_out.dart';
import 'package:bai_market/core/pin_storage.dart';
import 'package:bai_market/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bai_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../widgets/otp_input.dart';
import 'package:bai_market/core/routing/app_routing.dart';
import 'package:bai_market/features/profile/presentation/cubit/current_user_cubit.dart';

class OtpPage extends StatelessWidget {
  const OtpPage({super.key, required this.phoneNumber});
  final String? phoneNumber;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthCubit(),
      child: _OtpPageContent(phoneNumber: phoneNumber),
    );
  }
}

class _OtpPageContent extends StatefulWidget {
  const _OtpPageContent({required this.phoneNumber});
  final String? phoneNumber;

  @override
  State<_OtpPageContent> createState() => _OtpPageContentState();
}

class _OtpPageContentState extends State<_OtpPageContent> {
  late TextEditingController _controller;
  static final platform = const MethodChannel('com.bai_market/sms');

  int _secondsLeft = 59;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _listenToSmsCode();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _resendCode() {
    setState(() => _secondsLeft = 59);
    _startTimer();
    context.read<AuthCubit>().sendOtp(phoneNumber: widget.phoneNumber ?? '');
  }

  Future<void> _listenToSmsCode() async {
    try {
      await platform.invokeMethod('getSmsCode');
    } catch (e) {
      debugPrint('Error getting SMS code: $e');
    }
  }

  void _verifyOtp(String code) {
    if (code.length != 4) return;
    context.read<AuthCubit>().verifyOtp(
      phoneNumber: widget.phoneNumber ?? '',
      code: code,
    );
  }

  Future<void> _onVerified(BuildContext context) async {
    final pinExists = await hasPin();
    if (!context.mounted) return;
    resetUserCubits(context);
    if (pinExists) {
      AppLock.unlock();
      // Гость мог прийти сюда с защищённого маршрута (диплинк на эфир, пуш) —
      // возвращаем его туда, а не на главную.
      context.go(takePendingProtectedLocation() ?? '/main');
      // Корзину подтягиваем ДО отложенного действия: если пользователь нажимал
      // «Купить» гостем, добавление должно лечь на уже загруженную корзину.
      context.read<CartCubit>().ensureLoaded();
      // Роль у нового пользователя своя — перечитываем, а не берём старую.
      context.read<CurrentUserCubit>().reload();
      PendingAuthAction.runAndClear();
    } else {
      // Первый вход — предлагаем задать PIN (PendingAuthAction сработает
      // после создания PIN в PinCreatePage).
      context.go('/create-pin');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timerText = '00:${_secondsLeft.toString().padLeft(2, '0')}';

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is CodeVerified) {
          _onVerified(context);
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back button
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: CupertinoButton(
                    padding: const EdgeInsets.all(12),
                    onPressed: () => context.pop(),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SvgPicture.asset(
                        'assets/icons/arrow_left.svg',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 52),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    l10n.enterCode,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                      color: mainColorLight,
                      fontFamily: 'Gilroy',
                      height: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 12),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    l10n.otpSubtitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black54,
                      fontFamily: 'Gilroy',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 28),

                // OTP input
                OtpInput(
                  externalController: _controller,
                  onCodeComplete: _verifyOtp,
                ),

                const SizedBox(height: 60),

                // Resend timer
                Center(
                  child:
                      _secondsLeft > 0
                          ? RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.black45,
                                fontFamily: 'Gilroy',
                              ),
                              children: [
                                TextSpan(text: '${l10n.resendCode} '),
                                TextSpan(
                                  text: timerText,
                                  style: const TextStyle(
                                    color: mainColorLight,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'Gilroy',
                                  ),
                                ),
                              ],
                            ),
                          )
                          : CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _resendCode,
                            child: Text(
                              l10n.resendCode,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                                fontFamily: 'Gilroy',
                              ),
                            ),
                          ),
                ),

                const Spacer(),

                // Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    height: 60,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(15),
                      color: darkButtonColor,
                      onPressed:
                          isLoading ? null : () => _verifyOtp(_controller.text),
                      child:
                          isLoading
                              ? const CupertinoActivityIndicator(
                                color: Colors.white,
                              )
                              : Text(
                                l10n.confirm,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  fontFamily: 'Gilroy',
                                ),
                              ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
