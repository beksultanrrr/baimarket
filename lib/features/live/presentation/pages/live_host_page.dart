import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/services/live_logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/live_host_args.dart';
import '../cubit/live_host_cubit.dart';
import '../cubit/live_room_cubit.dart';
import '../widgets/host_controls_bar.dart';
import '../widgets/host_product_picker_sheet.dart';
import '../widgets/live_floating_chat.dart';
import '../widgets/live_shopping_scope.dart';
import 'live_page.dart' show LiveBadge;

/// Экран ведущего.
///
/// Публикует камеру и микрофон в LiveKit и одновременно сидит в нашем сокете
/// `/live` — без `joinStream` продавец не увидит даже собственный чат.
///
/// Токен приходит только из ответа `POST /live/start`: `POST /live/:id/token`
/// отдаёт зрительский, публиковать с ним нельзя. Поэтому без [LiveHostArgs]
/// открыть экран невозможно.
class LiveHostPage extends StatefulWidget {
  const LiveHostPage({super.key, required this.args});

  final LiveHostArgs args;

  @override
  State<LiveHostPage> createState() => _LiveHostPageState();
}

class _LiveHostPageState extends State<LiveHostPage> with WidgetsBindingObserver {
  static const _log = LiveLogger();

  late final LiveRoomCubit _room;
  late final LiveHostCubit _host;

  Room? _lkRoom;
  EventsListener<RoomEvent>? _listener;
  LocalVideoTrack? _preview;

  bool _micEnabled = true;
  bool _cameraEnabled = true;
  bool _frontCamera = true;
  bool _pausedByLifecycle = false;
  bool _stopping = false;

  int get _streamId => widget.args.stream.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Общий с вкладкой «Эфиры»: иначе завершение эфира здесь не гасило бы
    // кнопку «Вернуться в свой эфир» там.
    _host = context.read<LiveHostCubit>();
    _room = LiveRoomCubit(
      streamId: _streamId,
      role: LiveRole.host,
      preview: widget.args.stream,
      // Publisher-токен уже на руках: заново его не получить.
      preAuthorized: widget.args.connection,
    )..start();
    LiveShoppingController.register(LiveShoppingController());
    _connectLiveKit();
  }

  @override
  void dispose() {
    LiveShoppingController.unregister();
    WidgetsBinding.instance.removeObserver(this);
    _teardownLiveKit();
    WakelockPlus.disable();
    _room.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Обязательно: targetSdk 36, а с Android 14 фоновый захват камеры без
        // foreground-сервиса с типом camera запрещён.
        if (_cameraEnabled && !_pausedByLifecycle) {
          _pausedByLifecycle = true;
          _setCamera(false, remember: false);
        }
      case AppLifecycleState.resumed:
        if (_pausedByLifecycle) {
          _pausedByLifecycle = false;
          if (_cameraEnabled) _setCamera(true, remember: false);
        }
        // Сокет мог пересоединиться в фоне — вне комнаты события не идут.
        _room.onResumed();
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _connectLiveKit() async {
    final connection = widget.args.connection;
    final room = Room(
      roomOptions: const RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultCameraCaptureOptions: CameraCaptureOptions(
          cameraPosition: CameraPosition.front,
          params: VideoParametersPresets.h720_169,
        ),
      ),
    );
    final listener = room.createListener();
    _lkRoom = room;
    _listener = listener;

    listener
      ..on<LocalTrackPublishedEvent>((_) => _refreshPreview())
      ..on<RoomReconnectingEvent>((_) => _log.warn('LiveKit: reconnecting'))
      ..on<RoomDisconnectedEvent>((e) {
        _log.warn('LiveKit: host disconnected', e.reason);
      });

    try {
      await room.connect(connection.url, connection.token);
      await room.localParticipant?.setCameraEnabled(true);
      await room.localParticipant?.setMicrophoneEnabled(true);
      await WakelockPlus.enable();
      _refreshPreview();
    } catch (e, st) {
      _log.error('LiveKit host connect failed', e.toString(), e, st);
      if (mounted) setState(() {});
    }
  }

  void _refreshPreview() {
    final participant = _lkRoom?.localParticipant;
    if (participant == null || !mounted) return;
    LocalVideoTrack? track;
    for (final publication in participant.videoTrackPublications) {
      final candidate = publication.track;
      if (candidate is LocalVideoTrack) {
        track = candidate;
        break;
      }
    }
    setState(() => _preview = track);
  }

  Future<void> _setCamera(bool enabled, {bool remember = true}) async {
    await _lkRoom?.localParticipant?.setCameraEnabled(enabled);
    if (!mounted) return;
    setState(() {
      if (remember) _cameraEnabled = enabled;
      if (!enabled) _preview = null;
    });
    if (enabled) _refreshPreview();
  }

  Future<void> _toggleMic() async {
    final next = !_micEnabled;
    await _lkRoom?.localParticipant?.setMicrophoneEnabled(next);
    if (mounted) setState(() => _micEnabled = next);
  }

  Future<void> _flipCamera() async {
    final track = _preview;
    if (track == null) return;
    final next = _frontCamera ? CameraPosition.back : CameraPosition.front;
    try {
      await track.setCameraPosition(next);
      if (mounted) setState(() => _frontCamera = !_frontCamera);
    } catch (e) {
      _log.warn('camera flip failed', e.toString());
    }
  }

  Future<void> _teardownLiveKit() async {
    _listener?.dispose();
    _listener = null;
    final room = _lkRoom;
    _lkRoom = null;
    if (room == null) return;
    // disconnect() асинхронный и умеет бросать TimeoutException; dispose —
    // строго после него, а не параллельно.
    try {
      await room.disconnect();
    } catch (e) {
      _log.warn('LiveKit host disconnect', e.toString());
    }
    await room.dispose();
  }

  /// Завершение эфира. Тот же путь вызывается из PopScope и dispose, потому что
  /// пропущенный `POST /live/:id/stop` оставляет на сервере живой эфир.
  Future<void> _stopStream({bool confirm = true}) async {
    if (_stopping) return;
    if (confirm) {
      final l10n = AppLocalizations.of(context)!;
      final agreed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: Text(l10n.streamStopConfirmTitle),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(l10n.streamStopConfirmAction),
            ),
          ],
        ),
      );
      if (agreed != true || !mounted) return;
    }

    setState(() => _stopping = true);
    await _host.stop(_streamId);
    await _teardownLiveKit();
    await WakelockPlus.disable();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/streams'); // live-nav-ok: эфир уже завершён
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _room),
      ],
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _stopStream();
        },
        child: BlocBuilder<LiveRoomCubit, LiveRoomState>(
          builder: (context, state) => _HostView(
            state: state,
            preview: _preview,
            mirror: _frontCamera,
            micEnabled: _micEnabled,
            cameraEnabled: _cameraEnabled,
            stopping: _stopping,
            onToggleMic: _toggleMic,
            onToggleCamera: () => _setCamera(!_cameraEnabled),
            onFlipCamera: _flipCamera,
            onPickProduct: () => _openProductPicker(context, state),
            onStop: _stopStream,
          ),
        ),
      ),
    );
  }

  Future<void> _openProductPicker(
    BuildContext context,
    LiveRoomState state,
  ) async {
    // sellerId приходит в теле 201 от /live/start — своей роли клиент не знает,
    // и это единственный способ узнать, чьи товары показывать.
    final sellerId = state.stream?.sellerId ?? widget.args.stream.sellerId;
    if (sellerId == null) return;
    await showHostProductPickerSheet(
      context: context,
      sellerId: sellerId,
      pinnedProductId: state.pinnedProduct?.id,
      onPick: _room.showProduct,
      onUnpin: _room.hideProduct,
    );
  }
}

class _HostView extends StatelessWidget {
  const _HostView({
    required this.state,
    required this.preview,
    required this.mirror,
    required this.micEnabled,
    required this.cameraEnabled,
    required this.stopping,
    required this.onToggleMic,
    required this.onToggleCamera,
    required this.onFlipCamera,
    required this.onPickProduct,
    required this.onStop,
  });

  final LiveRoomState state;
  final LocalVideoTrack? preview;
  final bool mirror;
  final bool micEnabled;
  final bool cameraEnabled;
  final bool stopping;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleCamera;
  final VoidCallback onFlipCamera;
  final VoidCallback onPickProduct;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final track = preview;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (track != null)
            VideoTrackRenderer(
              track,
              fit: VideoViewFit.cover,
              // Зеркалим только фронтальную: задняя в зеркале выглядит сломанной.
              mirrorMode:
                  mirror ? VideoViewMirrorMode.mirror : VideoViewMirrorMode.off,
            )
          else
            ColoredBox(
              color: const Color(0xFF1E1E1E),
              child: Center(
                child: Text(
                  cameraEnabled ? '' : l10n.hostCameraPaused,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 15,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xCC000000),
                      Colors.transparent,
                      Color(0xE6000000),
                    ],
                    stops: [0.0, 0.32, 1.0],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _HostHeader(
                  title: state.stream?.title ?? '',
                  viewerCount: state.viewerCount,
                  stopping: stopping,
                  onStop: onStop,
                ),
                const Spacer(),
                // Лента чата скроллится, поэтому ей нужна конечная высота:
                // в Column со Spacer её иначе нет.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    height: 200,
                    child: LiveFloatingChat(messages: state.chat),
                  ),
                ),
                const SizedBox(height: 14),
                if (state.pinnedProduct != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _PinnedBadge(
                      name: state.pinnedProduct!.name ?? '',
                      label: l10n.pinnedProductBadge,
                    ),
                  ),
                const SizedBox(height: 12),
                HostControlsBar(
                  micEnabled: micEnabled,
                  cameraEnabled: cameraEnabled,
                  onToggleMic: onToggleMic,
                  onToggleCamera: onToggleCamera,
                  onFlipCamera: onFlipCamera,
                  onPickProduct: onPickProduct,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HostHeader extends StatelessWidget {
  const _HostHeader({
    required this.title,
    required this.viewerCount,
    required this.stopping,
    required this.onStop,
  });

  final String title;
  final int viewerCount;
  final bool stopping;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    SvgPicture.asset('assets/icons/view.svg',
                        width: 11, height: 11),
                    const SizedBox(width: 5),
                    Text(
                      viewerCount.toString(),
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const LiveBadge(),
          const SizedBox(width: 10),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(34, 34),
            onPressed: stopping ? null : onStop,
            child: stopping
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : SvgPicture.asset(
                    'assets/icons/cancel_stream.svg',
                    width: 30,
                    height: 30,
                  ),
          ),
        ],
      ),
    );
  }
}

class _PinnedBadge extends StatelessWidget {
  const _PinnedBadge({required this.name, required this.label});
  final String name;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF71CD32),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
