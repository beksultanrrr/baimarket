import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../../../core/services/live_logger.dart';

/// Подключается к комнате LiveKit Cloud и рендерит видеотрек хоста.
///
/// Строго subscribe-only: камеру/микрофон не публикуем. Виджет сам управляет
/// жизненным циклом `Room` (connect в initState, disconnect/dispose в dispose).
/// При смене `token`/`url` пересоздаёт соединение.
class LiveKitPlayer extends StatefulWidget {
  const LiveKitPlayer({
    super.key,
    required this.url,
    required this.token,
    this.roomName,
    this.logger = const LiveLogger(),
  });

  final String url;
  final String token;
  final String? roomName;
  final LiveLogger logger;

  @override
  State<LiveKitPlayer> createState() => _LiveKitPlayerState();
}

enum _PlayerStatus { connecting, playing, noVideo, error }

class _LiveKitPlayerState extends State<LiveKitPlayer> {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  VideoTrack? _videoTrack;
  _PlayerStatus _status = _PlayerStatus.connecting;

  LiveLogger get _log => widget.logger;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void didUpdateWidget(covariant LiveKitPlayer old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url || old.token != widget.token) {
      _teardown();
      setState(() {
        _videoTrack = null;
        _status = _PlayerStatus.connecting;
      });
      _connect();
    }
  }

  Future<void> _connect() async {
    final room = Room(
      roomOptions: const RoomOptions(
        adaptiveStream: true,
        dynacast: true,
      ),
    );
    final listener = room.createListener();
    _room = room;
    _listener = listener;

    listener
      ..on<TrackSubscribedEvent>((_) => _pickVideoTrack())
      ..on<TrackUnsubscribedEvent>((_) => _pickVideoTrack())
      ..on<ParticipantConnectedEvent>((_) => _pickVideoTrack())
      ..on<ParticipantDisconnectedEvent>((_) => _pickVideoTrack())
      ..on<RoomDisconnectedEvent>((e) {
        _log.warn('LiveKit room disconnected', e.reason);
        if (mounted && _videoTrack == null) {
          setState(() => _status = _PlayerStatus.error);
        }
      });

    try {
      _log.connect('LiveKit connecting', widget.url);
      await room.connect(widget.url, widget.token);
      _log.connect('LiveKit connected, room=${room.name}');
      _pickVideoTrack();
    } catch (e) {
      _log.error('LiveKit connect failed', e);
      if (mounted) setState(() => _status = _PlayerStatus.error);
    }
  }

  /// Ищет первый доступный видеотрек среди ремоут-участников.
  void _pickVideoTrack() {
    final room = _room;
    if (room == null || !mounted) return;

    VideoTrack? found;
    for (final p in room.remoteParticipants.values) {
      for (final pub in p.videoTrackPublications) {
        final track = pub.track;
        if (track is VideoTrack && pub.subscribed) {
          found = track;
          break;
        }
      }
      if (found != null) break;
    }

    setState(() {
      _videoTrack = found;
      _status = found != null ? _PlayerStatus.playing : _PlayerStatus.noVideo;
    });
  }

  void _teardown() {
    _listener?.dispose();
    _listener = null;
    final room = _room;
    _room = null;
    if (room == null) return;
    // disconnect() асинхронный и может бросить TimeoutException (сервер не
    // успел подтвердить выход) — глушим, иначе всплывает Unhandled Exception.
    // dispose() только после завершения disconnect, а не параллельно с ним.
    () async {
      try {
        await room.disconnect();
      } catch (e) {
        _log.warn('LiveKit disconnect', e);
      }
      await room.dispose();
    }();
  }

  @override
  void dispose() {
    _teardown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = _videoTrack;
    if (track != null) {
      // Заполняем весь экран вертикально (cover обрезает края), как в
      // TikTok/Instagram Live — без чёрных полос 16:9.
      return SizedBox.expand(
        child: ClipRect(
          child: VideoTrackRenderer(
            track,
            fit: VideoViewFit.cover,
          ),
        ),
      );
    }
    return _PlaceholderView(status: _status);
  }
}

class _PlaceholderView extends StatelessWidget {
  const _PlaceholderView({required this.status});
  final _PlayerStatus status;

  @override
  Widget build(BuildContext context) {
    final isError = status == _PlayerStatus.error;
    final isLoading = status == _PlayerStatus.connecting;
    return ColoredBox(
      color: const Color(0xFF1E1E1E),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator(
                color: Colors.white24,
                strokeWidth: 2,
              )
            : Icon(
                isError ? Icons.error_outline_rounded : Icons.live_tv_rounded,
                color: Colors.white24,
                size: 56,
              ),
      ),
    );
  }
}
