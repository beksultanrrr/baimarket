import 'package:bai_market/core/app_pallete.dart';
import 'package:bai_market/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/pending_action.dart';
import '../../../../core/services/global_config_service.dart';
import '../../../../core/widgets/consent_text.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/phone_number_input.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final AuthCubit _cubit = AuthCubit();
  final TextEditingController _controller = TextEditingController();

  /// Распознаватели нажатий по ссылкам в тексте согласия. Создаются один раз:
  /// они переживают перестроения и освобождаются в [dispose].
  late final TapGestureRecognizer _offerTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _offerTap = TapGestureRecognizer()..onTap = () => _openDoc(offer: true);
    _privacyTap = TapGestureRecognizer()..onTap = () => _openDoc(offer: false);
    // Конфиг тянем заранее, чтобы нажатие открывало документ сразу, без
    // ожидания сети. Промах не критичен — на тапе будет вторая попытка.
    GlobalConfigService.load();
  }

  /// Открывает юридический документ, ссылка на который лежит в `/globalConfig`:
  /// оферту ([offer]) или политику конфиденциальности.
  Future<void> _openDoc({required bool offer}) async {
    final l10n = AppLocalizations.of(context)!;
    final label = offer ? l10n.userAgreement : l10n.privacyPolicy;
    final config = GlobalConfigService.cached ?? await GlobalConfigService.load();
    final url = offer ? config?.offerDocUrl : config?.privacyDocUrl;
    if (await openDocumentUrl(url) || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.failedToOpen(label)), backgroundColor: Colors.redAccent));
  }

  @override
  void dispose() {
    _controller.dispose();
    _offerTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  String get _digits => _controller.text.replaceAll(RegExp(r'\D'), '');

  void _submit() {
    debugPrint('📱 controller.text = "${_controller.text}"');
    debugPrint('📱 digits = "$_digits"');
    if (_digits.isEmpty) {
      debugPrint('❌ digits empty, aborting');
      return;
    }
    debugPrint('🚀 calling sendOtp...');
    _cubit.sendOtp(phoneNumber: _digits);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<AuthCubit, AuthState>(
      bloc: _cubit,
      listener: (context, state) {
        debugPrint('🔔 AuthState changed: ${state.runtimeType}');
        if (state is CodeSended) {
          debugPrint('✅ CodeSended → navigating to OTP');
          context.push('/auth/otp/$_digits');
        }
        if (state is AuthError) {
          debugPrint('❌ AuthError: ${state.message}');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent));
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return Scaffold(
          backgroundColor: const Color(0xFFF7F7F7),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: CupertinoButton(
                      padding: const EdgeInsets.all(12),
                      onPressed: () {
                        PendingAuthAction.clear();
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/main');
                        }
                      },
                      child: SvgPicture.asset('assets/icons/arrow_left.svg', width: 24, height: 24),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(l10n.phoneNumber, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: mainColorLight, fontFamily: 'Gilroy'), textAlign: TextAlign.center),
                ),

                const SizedBox(height: 12),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Text(l10n.weWillSendSms, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.black54, fontFamily: 'Gilroy'), textAlign: TextAlign.center),
                ),

                const SizedBox(height: 24),

                // Phone input
                Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: PhoneNumberInput(controller: _controller, onCountryChanged: (_) {})),

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
                      onPressed: isLoading ? null : _submit,
                      child:
                          isLoading
                              ? const CupertinoActivityIndicator(color: Colors.white)
                              : Text(l10n.getCode, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white, fontFamily: 'Gilroy')),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Terms
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54, fontFamily: 'Gilroy'),
                      children: _termsSpans(l10n, offerTap: _offerTap, privacyTap: _privacyTap),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Builds the terms notice, highlighting the "user agreement" and
/// "privacy policy" phrases in green while the rest inherits the parent style.
/// The link labels come from localization and match verbatim substrings of
/// [AppLocalizations.termsAndPrivacy], so it works across en/ru/kk.
///
/// Каждая подсвеченная фраза кликабельна: [offerTap] открывает оферту,
/// [privacyTap] — политику конфиденциальности (ссылки приходят из
/// `/globalConfig`). Сама нарезка живёт в `core/widgets/consent_text.dart` —
/// её же использует согласие под кнопкой оформления заказа.
List<InlineSpan> _termsSpans(AppLocalizations l10n, {required TapGestureRecognizer offerTap, required TapGestureRecognizer privacyTap}) {
  const linkStyle = TextStyle(color: mainColorLight, fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'Gilroy', decoration: TextDecoration.underline, decorationColor: mainColorLight);
  return buildConsentSpans(
    text: l10n.termsAndPrivacy,
    links: {l10n.userAgreement: offerTap, l10n.privacyPolicy: privacyTap},
    linkStyle: linkStyle,
  );
}
