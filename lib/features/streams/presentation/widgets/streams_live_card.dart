import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../live/data/livekit_config.dart';
import '../../../live/data/models/live_stream_info.dart';
import '../../../live/presentation/cubit/live_cubit.dart';
import 'streams_avatar_list.dart';

/// Большая «Сейчас в эфире» карточка из Figma frame 10.
///
/// Размер 350×440 (как в макете). Если передан активный [live] — данные
/// и бэйдж берутся из него и карточка кликабельна (→ `/live`). Иначе —
/// чисто визуальная заглушка по моку (для каналов на которые подписан
/// пользователь, но эфир не идёт).
class StreamsLiveCard extends StatelessWidget {
  const StreamsLiveCard({
    super.key,
    required this.stream,
    this.live,
  });

  final StreamInfo stream;
  final LiveState? live;

  bool get _isLive =>
      (live?.isStreamActive == true && live?.streamInfo != null) ||
      kLiveKitDevEnabled;

  /// Метаданные эфира: из стейта, либо синтетические dev-данные.
  LiveStreamInfo? get _info =>
      live?.streamInfo ?? (kLiveKitDevEnabled ? devLiveStreamInfo() : null);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final info = _info;
    final title = _isLive ? (info?.channelTitle ?? stream.name) : stream.name;
    final desc = _isLive
        ? '${l10n.viewersLabel}: ${live?.viewerCount ?? 0}'
        : stream.description;
    final image = _isLive
        ? (info?.thumbnailUrl ?? stream.imageUrl)
        : stream.imageUrl;

    final card = Container(
      height: 440,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image.isNotEmpty)
            Image.network(
              image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          // Низ-к-верху лёгкое затемнение для контраста подписи.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.5, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLive) ...[
                  _OnAirBadge(label: l10n.onAirNow),
                  const SizedBox(height: 10),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  desc,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!_isLive) return card;
    return GestureDetector(
      onTap: () => context.push('/live'),
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}

class _OnAirBadge extends StatelessWidget {
  const _OnAirBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF73030), Color(0xFFFD7E7E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          letterSpacing: 0.22,
          height: 1.0,
        ),
      ),
    );
  }
}
