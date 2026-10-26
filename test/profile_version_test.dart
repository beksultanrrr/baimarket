import 'package:bai_market/features/profile/presentation/widgets/app_version_label.dart';
import 'package:bai_market/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Строка версии внизу профиля берёт номер из PackageInfo, а не из константы.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget harness(Locale locale) => MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: AppVersionLabel()),
      );

  testWidgets('показывает версию из PackageInfo', (tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'Bai Market',
      packageName: 'kz.iris.baimarket',
      version: '1.23.0',
      buildNumber: '25',
      buildSignature: '',
    );

    await tester.pumpWidget(harness(const Locale('ru')));
    await tester.pumpAndSettle();

    expect(find.text('Версия: 1.23.0'), findsOneWidget);
  });

  testWidgets('прижата к левому краю, а не по центру', (tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'Bai Market',
      packageName: 'kz.iris.baimarket',
      version: '1.23.0',
      buildNumber: '25',
      buildSignature: '',
    );

    // Column профиля центрирует детей — строка должна прижиматься сама.
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: Column(children: [AppVersionLabel()]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final text = tester.getRect(find.text('Версия: 1.23.0'));
    final screen = tester.getRect(find.byType(Scaffold));
    expect(
      text.left - screen.left,
      lessThan(24),
      reason: 'строка должна быть у левого края, а не по центру',
    );
  });

  testWidgets('переводится на kk и en', (tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'Bai Market',
      packageName: 'kz.iris.baimarket',
      version: '1.23.0',
      buildNumber: '25',
      buildSignature: '',
    );

    for (final locale in const [Locale('kk'), Locale('en')]) {
      await tester.pumpWidget(harness(locale));
      await tester.pumpAndSettle();

      // Номер виден в любой локали, а подпись вокруг — своя.
      expect(
        find.textContaining('1.23.0'),
        findsOneWidget,
        reason: 'локаль ${locale.languageCode}',
      );
      expect(find.text('Версия: 1.23.0'), findsNothing);
    }
  });
}
