import 'package:bai_market/core/widgets/consent_text.dart';
import 'package:bai_market/l10n/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Согласие под кнопкой оформления заказа и под «Получить код» подсвечивает
/// ссылки, находя подписи как подстроки. Если переводчик поправит фразу и
/// забудет метку — ссылка молча исчезнет, поэтому связку проверяем тестом.
void main() {
  group('метки встречаются во фразе дословно', () {
    for (final locale in const [Locale('ru'), Locale('kk'), Locale('en')]) {
      test('оформление заказа — ${locale.languageCode}', () async {
        final l10n = await AppLocalizations.delegate.load(locale);
        expect(
          l10n.orderConsentText.contains(l10n.orderConsentOffer),
          isTrue,
          reason: 'в orderConsentText нет orderConsentOffer',
        );
        expect(
          l10n.orderConsentText.contains(l10n.orderConsentPrivacy),
          isTrue,
          reason: 'в orderConsentText нет orderConsentPrivacy',
        );
      });

      test('авторизация — ${locale.languageCode}', () async {
        final l10n = await AppLocalizations.delegate.load(locale);
        expect(l10n.termsAndPrivacy.contains(l10n.userAgreement), isTrue);
        expect(l10n.termsAndPrivacy.contains(l10n.privacyPolicy), isTrue);
      });
    }
  });

  test('нарезка: обе метки становятся ссылками, текст не теряется', () {
    final offer = TapGestureRecognizer();
    final privacy = TapGestureRecognizer();
    addTearDown(offer.dispose);
    addTearDown(privacy.dispose);

    const linkStyle = TextStyle(color: Color(0xFF71CD32));
    final spans = buildConsentSpans(
      text: 'Соглашаетесь с Условиями оферты и Политикой конфиденциальности',
      links: {'Условиями оферты': offer, 'Политикой конфиденциальности': privacy},
      linkStyle: linkStyle,
    );

    // Склейка всех кусков обязана вернуть исходную строку — ничего не
    // потеряно и не задвоено.
    final joined = spans.map((s) => (s as TextSpan).text).join();
    expect(
      joined,
      'Соглашаетесь с Условиями оферты и Политикой конфиденциальности',
    );

    final linked = spans
        .cast<TextSpan>()
        .where((s) => s.recognizer != null)
        .map((s) => s.text)
        .toList();
    expect(linked, ['Условиями оферты', 'Политикой конфиденциальности']);
  });

  test('метки нет в тексте — остаётся обычный текст, без падения', () {
    final tap = TapGestureRecognizer();
    addTearDown(tap.dispose);

    final spans = buildConsentSpans(
      text: 'Текст без ссылок',
      links: {'Оферта': tap},
      linkStyle: const TextStyle(),
    );

    expect(spans.length, 1);
    expect((spans.single as TextSpan).recognizer, isNull);
  });
}
