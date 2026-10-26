import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../live/presentation/cubit/live_host_cubit.dart';
import '../../../live/presentation/cubit/live_list_cubit.dart';
import '../../../live/presentation/widgets/start_stream_button.dart';
import '../../../menu/presentation/providers/bottom_nav_provider.dart';
import '../../../profile/presentation/cubit/current_user_cubit.dart';
import '../../../stories/presentation/cubit/stories_cubit.dart';
import '../../../stories/presentation/widgets/stories_row.dart';
import '../widgets/streams_app_bar.dart';
import '../widgets/streams_live_card.dart';

/// Вкладка «Эфиры»: лента идущих трансляций из `GET /live`.
///
/// Раньше здесь синтезировался один фейковый эфир из состояния сокета —
/// ручки списка приложение не вызывало вообще.
class StreamsPage extends StatefulWidget {
  const StreamsPage({super.key});

  @override
  State<StreamsPage> createState() => _StreamsPageState();
}

class _StreamsPageState extends State<StreamsPage> with WidgetsBindingObserver {
  final LiveListCubit _liveList = LiveListCubit();
  final StoriesCubit _stories = StoriesCubit();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _liveList.close();
    _stories.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Поллинг не должен работать, пока приложение в фоне: это лишние запросы
    // у каждого пользователя.
    if (state == AppLifecycleState.resumed) {
      _liveList.refresh();
    } else {
      _liveList.stopPolling();
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _liveList.refresh(),
      if (_canStream) _host.loadMyActiveStream(),
      _stories.refresh(),
    ]);
  }

  /// `GET /live/my` имеет смысл только для тех, кто вообще может вещать.
  /// Для покупателя это гарантированно пустой ответ на каждое открытие
  /// вкладки.
  bool get _canStream =>
      context.read<CurrentUserCubit>().state.canOpenStreaming;

  /// Общий с экраном ведущего — он же его и гасит при завершении эфира.
  LiveHostCubit get _host => context.read<LiveHostCubit>();

  /// Загружаем и опрашиваем только пока вкладка действительно открыта.
  /// `StreamsPage` живёт в `IndexedStack` и смонтирована всегда, так что
  /// `initState` сработал бы на холодном старте у всех подряд.
  void _onTabChanged(bool selected) {
    if (selected) {
      _liveList.ensureLoaded();
      _liveList.startPolling();
      // Идёт ли у меня эфир прямо сейчас — от этого зависит, что написано на
      // кнопке. Любая ошибка означает «нет», гость её увидеть не должен.
      if (_canStream) _host.loadMyActiveStream();
      _stories.ensureLoaded();
    } else {
      _liveList.stopPolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    return riverpod.Consumer(
      builder: (context, ref, _) {
        final selected =
            ref.watch(bottomNavIndexProvider) == kMenuTabStreams;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _onTabChanged(selected);
        });
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: const Color(0xFF1E1E1E),
            body: SafeArea(
              bottom: false,
              child: MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: _liveList),
                  BlocProvider.value(value: _stories),
                ],
                // Свой эфир только что завершили — перечитываем ленту, иначе
                // он провисит в ней до следующего опроса (45 с).
                child: BlocListener<LiveHostCubit, LiveHostState>(
                  listenWhen: (prev, next) =>
                      prev.activeStream != null && next.activeStream == null,
                  listener: (_, __) => _liveList.refresh(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StreamsAppBar(),
                      // Порядок сверху вниз: шапка → «Начать эфир» → сториз →
                      // лента.
                      const StartStreamButton(),
                      // Пустая лента сториз схлопывается целиком — ряд владеет
                      // и своим отступом.
                      const StoriesRow(),
                      Expanded(
                        child: AppRefreshIndicator(
                          onRefresh: _onRefresh,
                          dark: true,
                          displacement: 24,
                          child: BlocBuilder<LiveListCubit, LiveListState>(
                            builder: (context, state) => _Body(state: state),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});
  final LiveListState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (state.status == LiveListStatus.loading && state.streams.isEmpty) {
      return const _CenteredScrollable(
        child: CircularProgressIndicator(color: Colors.white24, strokeWidth: 2),
      );
    }
    if (state.status == LiveListStatus.error && state.streams.isEmpty) {
      return _CenteredScrollable(
        child: _Placeholder(
          icon: Icons.wifi_off_rounded,
          title: l10n.streamsLoadError,
          subtitle: l10n.pullToRefreshHint,
        ),
      );
    }
    if (state.streams.isEmpty) {
      return _CenteredScrollable(
        child: _Placeholder(
          icon: Icons.live_tv_rounded,
          title: l10n.streamsEmptyTitle,
          subtitle: l10n.streamsEmptySubtitle,
        ),
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: state.streams.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) => StreamsLiveCard(stream: state.streams[i]),
    );
  }
}

/// Пустые состояния должны оставаться прокручиваемыми — иначе на них не
/// сработает pull-to-refresh, а это единственный способ повторить запрос.
class _CenteredScrollable extends StatelessWidget {
  const _CenteredScrollable({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Center(child: child),
        ),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white24, size: 72),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white60,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
