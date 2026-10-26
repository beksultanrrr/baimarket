import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/show_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../live/data/models/live_media.dart';
import '../../../live/data/models/live_stream_model.dart';

/// Карточка идущего эфира в ленте.
///
/// Всё, что приходит из `GET /live`, уже в статусе LIVE, поэтому отдельного
/// «не в эфире» состояния у карточки нет — раньше оно существовало только
/// потому, что список был выдуманным.
///
/// Видео здесь не играет: каждая играющая карточка — отдельное WebRTC-
/// подключение и отдельный тарифицируемый участник комнаты, плюс свой запрос
/// токена. Показываем обложку, а видео начинается после тапа.
class StreamsLiveCard extends StatelessWidget {
  const StreamsLiveCard({super.key, required this.stream});

  final LiveStreamModel stream;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final image = liveCoverImageUrl(stream);
    final title = (stream.title ?? '').trim();
    final sellerName = stream.seller?.displayName ?? '';

    return GestureDetector(
      onTap: () => context.push('/live/${stream.id}', extra: stream),
      behavior: HitTestBehavior.opaque,
      child: Container(
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
            // У только что начатого эфира нет ни обложки, ни закреплённого
            // товара — тогда остаётся брендовая заглушка и заголовок поверх.
            NetworkImageWidget(url: image, dark: true, solidFallback: true),
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
                  _OnAirBadge(label: l10n.onAirNow),
                  const SizedBox(height: 10),
                  Text(
                    title.isNotEmpty ? title : sellerName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
                    '${l10n.viewersLabel}: ${stream.viewerCount}',
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
      ),
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
