import 'package:bai_market/features/app_update/data/models/app_update_info.dart';
import 'package:bai_market/features/app_update/data/models/app_version.dart';
import 'package:bai_market/features/app_update/domain/repositories/app_update_repository.dart';
import 'package:bai_market/features/app_update/presentation/cubit/app_update_cubit.dart';
import 'package:bai_market/features/app_update/presentation/widgets/app_update_gate.dart';
import 'package:bai_market/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRepository implements AppUpdateRepository {
  _FakeRepository(this.result);

  final AppUpdateInfo? result;
  int calls = 0;

  @override
  Future<AppUpdateInfo?> checkForUpdate() async {
    calls++;
    return result;
  }
}

AppUpdateInfo _info(AppUpdateSeverity severity) => AppUpdateInfo(
  severity: severity,
  currentVersion: AppVersion.tryParse('1.0.7')!,
  latestVersion: AppVersion.tryParse(
    severity == AppUpdateSeverity.forced ? '2.0.0' : '1.1.0',
  )!,
  storeUrl: 'https://example.com/app',
);

Widget _harness(AppUpdateCubit cubit) {
  return BlocProvider.value(
    value: cubit,
    child: MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru'), Locale('en'), Locale('kk')],
      // Тот же монтаж, что в main.dart: гейт живёт выше навигатора.
      builder: (context, child) =>
          AppUpdateGate(child: child ?? const SizedBox.shrink()),
      home: const Scaffold(body: Center(child: Text('под оверлеем'))),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('обязательное обновление не закрывается тапом по затемнению', (
    tester,
  ) async {
    final cubit = AppUpdateCubit(
      repository: _FakeRepository(_info(AppUpdateSeverity.forced)),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(_harness(cubit));
    await tester.pumpAndSettle();

    expect(find.text('Требуется обновление'), findsOneWidget);
    // У обязательного обновления нет пути наружу вообще: ни «Позже»…
    expect(find.text('Позже'), findsNothing);

    // …ни тапа по затемнению.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Требуется обновление'), findsOneWidget);
  });

  testWidgets('обязательное переживает повторные проверки', (tester) async {
    // Проверка после возврата из фона вернула null (сеть отвалилась) — диалог
    // обязан остаться на месте.
    final repo = _FakeRepository(_info(AppUpdateSeverity.forced));
    final cubit = AppUpdateCubit(repository: repo);
    addTearDown(cubit.close);

    await tester.pumpWidget(_harness(cubit));
    await tester.pumpAndSettle();
    expect(find.text('Требуется обновление'), findsOneWidget);

    await cubit.check(force: true);
    await tester.pumpAndSettle();
    expect(find.text('Требуется обновление'), findsOneWidget);
    // Кубит заморожен — второй запрос в сеть даже не ушёл.
    expect(repo.calls, 1);
  });

  testWidgets('рекомендованное закрывается кнопкой «Позже»', (tester) async {
    final cubit = AppUpdateCubit(
      repository: _FakeRepository(_info(AppUpdateSeverity.recommended)),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(_harness(cubit));
    await tester.pumpAndSettle();

    expect(find.text('Вышла новая версия'), findsOneWidget);
    expect(find.text('Версия 1.1.0'), findsOneWidget);

    await tester.tap(find.text('Позже'));
    await tester.pumpAndSettle();

    expect(find.text('Вышла новая версия'), findsNothing);
    expect(find.text('под оверлеем'), findsOneWidget);
  });

  testWidgets('отложенное не показывается повторно', (tester) async {
    final repo = _FakeRepository(_info(AppUpdateSeverity.recommended));
    final first = AppUpdateCubit(repository: repo);
    addTearDown(first.close);

    await tester.pumpWidget(_harness(first));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Позже'));
    await tester.pumpAndSettle();

    // Следующий запуск приложения — новый кубит, те же SharedPreferences.
    final second = AppUpdateCubit(repository: repo);
    addTearDown(second.close);
    await tester.pumpWidget(_harness(second));
    await tester.pumpAndSettle();

    expect(find.text('Вышла новая версия'), findsNothing);
  });

  testWidgets('без обновления оверлея нет', (tester) async {
    final cubit = AppUpdateCubit(
      repository: _FakeRepository(_info(AppUpdateSeverity.none)),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(_harness(cubit));
    await tester.pumpAndSettle();

    expect(find.text('Вышла новая версия'), findsNothing);
    expect(find.text('Требуется обновление'), findsNothing);
    expect(find.text('под оверлеем'), findsOneWidget);
  });

  testWidgets('недоступный источник не блокирует приложение', (tester) async {
    final cubit = AppUpdateCubit(repository: _FakeRepository(null));
    addTearDown(cubit.close);

    await tester.pumpWidget(_harness(cubit));
    await tester.pumpAndSettle();

    expect(cubit.state, isA<AppUpdateNotRequired>());
    expect(find.text('под оверлеем'), findsOneWidget);
  });
}
