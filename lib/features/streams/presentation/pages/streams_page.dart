import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../live/data/livekit_config.dart';
import '../../../live/presentation/cubit/live_cubit.dart';
import '../widgets/streams_app_bar.dart';
import '../widgets/streams_avatar_list.dart';
import '../widgets/streams_live_card.dart';

class StreamsPage extends StatefulWidget {
  const StreamsPage({super.key});

  @override
  State<StreamsPage> createState() => _StreamsPageState();
}

class _StreamsPageState extends State<StreamsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LiveCubit>().connect();
    });
  }

  Future<void> _onRefresh() async {
    await context.read<LiveCubit>().refreshNow();
  }

  StreamInfo _activeStreamInfo(LiveState live) {
    final info = live.streamInfo ?? devLiveStreamInfo();
    return StreamInfo(
      id: 'live',
      imageUrl: info.thumbnailUrl ?? '',
      name: info.channelTitle,
      description: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<LiveCubit, LiveState>(
            builder: (context, live) {
              // Dev-обход: при заданном ручном LiveKit-токене показываем
              // активную карточку (→ /live) без сокет-события streamStarted.
              final hasLive =
                  (live.isStreamActive && live.streamInfo != null) ||
                      kLiveKitDevEnabled;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StreamsAppBar(),
                  if (hasLive) ...[
                    StreamsAvatarList(
                      streams: [_activeStreamInfo(live)],
                      activeId: 'live',
                      onSelect: (_) {},
                    ),
                    const SizedBox(height: 8),
                  ],
                  Expanded(
                    child: AppRefreshIndicator(
                      onRefresh: _onRefresh,
                      dark: true,
                      displacement: 24,
                      child: hasLive
                          ? _ActiveStreamBody(
                              stream: _activeStreamInfo(live),
                              live: live,
                            )
                          : const _NoStreamBody(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ActiveStreamBody extends StatelessWidget {
  const _ActiveStreamBody({required this.stream, required this.live});
  final StreamInfo stream;
  final LiveState live;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        StreamsLiveCard(stream: stream, live: live),
      ],
    );
  }
}

class _NoStreamBody extends StatelessWidget {
  const _NoStreamBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.live_tv_rounded,
                    color: Colors.white24,
                    size: 72,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.streamInactiveTitle,
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
                    l10n.streamInactiveSubtitle,
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
            ),
          ),
        ),
      ],
    );
  }
}
