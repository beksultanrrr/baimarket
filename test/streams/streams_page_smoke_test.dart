import 'package:bai_market/features/profile/data/models/current_user_model.dart';
import 'package:bai_market/features/profile/data/models/profile_model.dart';
import 'package:bai_market/features/profile/domain/repositories/profile_repository.dart';
import 'package:bai_market/features/profile/presentation/cubit/current_user_cubit.dart';
import 'package:bai_market/features/live/domain/repositories/live_repository.dart';
import 'package:bai_market/features/live/presentation/cubit/live_host_cubit.dart';
import 'package:bai_market/features/live/presentation/widgets/start_stream_button.dart';
import 'package:bai_market/features/streams/presentation/pages/streams_page.dart';
import 'package:bai_market/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this.result);
  final CurrentUserResult result;

  @override
  Future<CurrentUserResult> getCurrentUser() async => result;

  @override
  Future<ProfileModel?> getProfileData() async => null;
}

/// Пустой репозиторий эфиров: странице для сборки хватает «ничего не идёт».
class _EmptyLiveRepository implements LiveRepository {
  @override
  Future<LiveListResult> getLiveStreams() async => const LiveListLoaded([]);
  @override
  Future<LiveListResult> getMyStreams() async => const LiveListLoaded([]);
  @override
  Future<LiveStreamResult> getStream(int id) async => const LiveStreamFailed();
  @override
  Future<LiveStartResult> startStream({
    required String title,
    String? coverUrl,
  }) async =>
      const LiveStartFailed();
  @override
  Future<LiveStopResult> stopStream(int id) async => const LiveStopFailed();
  @override
  Future<LiveViewerTokenResult> getViewerToken(int id) async =>
      const LiveViewerTokenFailed();
  @override
  Future<LiveChatHistoryResult> getChatHistory(int id) async =>
      const LiveChatHistoryLoaded([]);
}

/// Вкладка «Эфиры» собирает вместе свои кубиты (лента, сториз), глобальные
/// `CurrentUserCubit` и `LiveHostCubit`, riverpod-провайдер таба и локализацию.
///
/// `flutter analyze` такого не ловит: пропущенный провайдер — это
/// `ProviderNotFoundException` в рантайме, а не ошибка компиляции.
void main() {
  Future<void> pumpPage(WidgetTester tester, CurrentUserResult user) async {
    final currentUser = CurrentUserCubit(
      profileRepository: _FakeProfileRepository(user),
    );
    addTearDown(currentUser.close);
    await currentUser.load();

    final host = LiveHostCubit(repository: _EmptyLiveRepository());
    addTearDown(host.close);

    await tester.pumpWidget(
      ProviderScope(
        // В приложении оба кубита лежат в глобальном MultiProvider в main.dart.
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: currentUser),
            BlocProvider.value(value: host),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('ru'),
            home: StreamsPage(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('строится со всеми своими провайдерами', (tester) async {
    await pumpPage(
      tester,
      CurrentUserLoaded(const CurrentUserModel(id: 1, role: 'USER')),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(StreamsPage), findsOneWidget);
  });

  testWidgets('покупатель не видит кнопку «Начать эфир»', (tester) async {
    await pumpPage(
      tester,
      CurrentUserLoaded(const CurrentUserModel(id: 1, role: 'USER')),
    );
    expect(find.byType(StartStreamButton), findsOneWidget);
    // Виджет в дереве есть, но рисует пустоту — по роли.
    expect(find.text('Начать эфир'), findsNothing);
  });

  testWidgets('гость не видит кнопку «Начать эфир»', (tester) async {
    await pumpPage(tester, const CurrentUserUnauthorized());
    expect(find.text('Начать эфир'), findsNothing);
  });

  testWidgets('продавец видит кнопку «Начать эфир»', (tester) async {
    await pumpPage(
      tester,
      CurrentUserLoaded(const CurrentUserModel(id: 1, role: 'SELLER')),
    );
    expect(find.text('Начать эфир'), findsOneWidget);
  });

  testWidgets('админ не видит кнопку «Начать эфир»', (tester) async {
    await pumpPage(
      tester,
      CurrentUserLoaded(const CurrentUserModel(id: 1, role: 'ADMIN')),
    );
    expect(find.text('Начать эфир'), findsNothing);
  });
}
