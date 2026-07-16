import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../collection/presentation/cubit/collection_cubit.dart';
import '../../data/livekit_config.dart';
import '../../data/models/live_stream_info.dart';
import '../cubit/live_cubit.dart';
import '../widgets/live_action_rail.dart';
import '../widgets/live_comments_sheet.dart';
import '../widgets/live_floating_chat.dart';
import '../widgets/live_gifts_sheet.dart';
import '../widgets/live_product_strip.dart';
import '../widgets/live_shopping_scope.dart';
import '../widgets/livekit_player.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  final CollectionCubit _collectionCubit = CollectionCubit();
  final FocusNode _inputFocus = FocusNode();
  YoutubePlayerController? _player;
  String? _currentVideoId;
  int _localLikes = 345; // мок, бэк сейчас не отдаёт лайки

  @override
  void initState() {
    super.initState();
    _collectionCubit.getCollection(slug: 'new', sort: 'popular');
    context.read<LiveCubit>().connect();
  }

  @override
  void dispose() {
    _player?.dispose();
    _collectionCubit.close();
    _inputFocus.dispose();
    super.dispose();
  }

  void _ensurePlayer(String videoId) {
    if (_currentVideoId == videoId && _player != null) return;
    _player?.dispose();
    _player = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        isLive: true,
        autoPlay: true,
        mute: false,
        enableCaption: false,
        forceHD: true,
        hideControls: true,
        hideThumbnail: true,
        disableDragSeek: true,
      ),
    );
    _currentVideoId = videoId;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LiveCubit, LiveState>(
      listenWhen: (prev, curr) => curr.lastError != null && prev.lastError != curr.lastError,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${state.lastError}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
            margin: const EdgeInsets.all(16),
          ),
        );
      },
      builder: (context, state) {
        final hasStream = state.isStreamActive && state.streamInfo != null;
        // Dev-обход: если задан ручной LiveKit-токен, показываем эфир даже без
        // сокет-события streamStarted (бэк ещё не интегрирован).
        if (!hasStream && !kLiveKitDevEnabled) {
          return _InactiveStreamView(onClose: () => context.pop());
        }
        final source = resolveLiveKitSource(state.streamInfo ?? devLiveStreamInfo());
        return _ActiveStreamView(
          state: state,
          streamInfo: source,
          videoPlayer: _buildVideoPlayer(source),
          collectionCubit: _collectionCubit,
          inputFocus: _inputFocus,
          likes: _localLikes,
          onLike: () => setState(() => _localLikes++),
          onSendMessage: (t) => context.read<LiveCubit>().sendMessage(t),
          onFocusChat: () => _inputFocus.requestFocus(),
        );
      },
    );
  }

  /// Строит видео-слой эфира: LiveKit, если бэк/dev-конфиг отдал комнату и
  /// токен; иначе — YouTube-фоллбэк по `videoId`.
  Widget _buildVideoPlayer(LiveStreamInfo source) {
    if (source.isLiveKit) {
      return LiveKitPlayer(
        url: source.livekitUrl!,
        token: source.token!,
        roomName: source.roomName,
      );
    }
    _ensurePlayer(source.videoId);
    // Лёгкий scale 1.18 + ClipRect прячут UI YouTube (LIVE-баннер, watermark,
    // кнопку "Watch on YouTube") за границами кропа. IgnorePointer глушит тачи
    // на iframe — иначе ютуб всплывает свой play/pause overlay при тапе.
    return Center(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRect(
          child: IgnorePointer(
            child: Transform.scale(
              scale: 1.18,
              child: YoutubePlayer(
                controller: _player!,
                showVideoProgressIndicator: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveStreamView extends StatelessWidget {
  const _ActiveStreamView({
    required this.state,
    required this.streamInfo,
    required this.videoPlayer,
    required this.collectionCubit,
    required this.inputFocus,
    required this.likes,
    required this.onLike,
    required this.onSendMessage,
    required this.onFocusChat,
  });

  final LiveState state;
  final LiveStreamInfo streamInfo;
  final Widget videoPlayer;
  final CollectionCubit collectionCubit;
  final FocusNode inputFocus;
  final int likes;
  final VoidCallback onLike;
  final ValueChanged<String> onSendMessage;
  final VoidCallback onFocusChat;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboardOpen = mq.viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Видео-слой фоном (LiveKit или YouTube-фоллбэк) — собирается в
          // _LivePageState._buildVideoPlayer и приходит сюда готовым.
          videoPlayer,
          // Затемнение сверху (под header) и снизу (под чат+ввод) — как в макете.
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
                _LiveHeader(
                  channelTitle: streamInfo.channelTitle,
                  thumbnailUrl: streamInfo.thumbnailUrl,
                  viewerCount: state.viewerCount,
                  onClose: () => context.pop(),
                ),
                const SizedBox(height: 12),
                if (!keyboardOpen)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _GiftButton(
                        onTap: () => showLiveGiftsSheet(
                          context: context,
                          collectionCubit: collectionCubit,
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: LiveFloatingChat(
                          messages: state.chatMessages,
                        ),
                      ),
                      if (!keyboardOpen) ...[
                        const SizedBox(width: 8),
                        LiveActionRail(
                          cartCount: _cartItemsCount(context),
                          messageCount: state.messageCount > 0 ? state.messageCount : state.chatMessages.length,
                          likesCount: likes,
                          onCartTap: () => openLiveCartSheet(context),
                          onMessageTap: () => showLiveCommentsSheet(
                            context: context,
                            cubit: context.read<LiveCubit>(),
                          ),
                          onLikeTap: onLike,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                BlocConsumer<CollectionCubit, CollectionState>(
                  bloc: collectionCubit,
                  listener: (_, __) {},
                  builder: (context, cs) {
                    if (cs is CollectionGot && cs.collection.products.isNotEmpty) {
                      return LiveProductStrip(products: cs.collection.products);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: _CommentInputRow(
                    focusNode: inputFocus,
                    canChat: state.isConnected && state.isStreamActive,
                    onSend: onSendMessage,
                  ),
                ),
                AnimatedPadding(
                  duration: const Duration(milliseconds: 150),
                  padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveHeader extends StatelessWidget {
  const _LiveHeader({
    required this.channelTitle,
    required this.thumbnailUrl,
    required this.viewerCount,
    required this.onClose,
  });

  final String channelTitle;
  final String? thumbnailUrl;
  final int viewerCount;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: ClipOval(
              child: thumbnailUrl != null && thumbnailUrl!.isNotEmpty
                  ? Image.network(
                      thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset('assets/images/person.png'),
                    )
                  : Image.asset('assets/images/person.png'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channelTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 0.26,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/view.svg',
                      width: 11,
                      height: 11,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      viewerCount.toString(),
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 0.22,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const _LiveBadge(),
          const SizedBox(width: 10),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(30, 30),
            onPressed: onClose,
            child: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD40176), Color(0xFFEC37CE)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/icons/stream/live_sun.svg',
            width: 16,
            height: 16,
          ),
          const SizedBox(width: 6),
          const Text(
            'LIVE',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.26,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftButton extends StatelessWidget {
  const _GiftButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF73030), Color(0xFFFD7E7E)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/stream/gift.svg',
              width: 20,
              height: 20,
            ),
            const SizedBox(width: 1),
            Text(
              l10n.giftButton,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                letterSpacing: 0.22,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentInputRow extends StatefulWidget {
  const _CommentInputRow({
    required this.focusNode,
    required this.canChat,
    required this.onSend,
  });
  final FocusNode focusNode;
  final bool canChat;
  final ValueChanged<String> onSend;

  @override
  State<_CommentInputRow> createState() => _CommentInputRowState();
}

class _CommentInputRowState extends State<_CommentInputRow> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    widget.onSend(t);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 25),
      alignment: Alignment.center,
      child: TextField(
        controller: _ctrl,
        focusNode: widget.focusNode,
        enabled: widget.canChat,
        onSubmitted: (_) => _send(),
        textInputAction: TextInputAction.send,
        cursorColor: Colors.white,
        style: const TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.white,
          height: 1.0,
        ),
        decoration: InputDecoration(
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          hintText: l10n.commentInputHint,
          hintStyle: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.75),
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

/// Считаем суммарное количество товаров в корзине из глобального CartCubit.
int _cartItemsCount(BuildContext context) {
  final state = context.watch<CartCubit>().state;
  if (state is CartGot) {
    final items = state.cart.cartItems ?? const [];
    return items.fold<int>(0, (sum, it) => sum + it.quantity);
  }
  if (state is CartGotAgain) {
    final items = state.cart.cartItems ?? const [];
    return items.fold<int>(0, (sum, it) => sum + it.quantity);
  }
  return 0;
}

class _InactiveStreamView extends StatelessWidget {
  const _InactiveStreamView({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 8,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(40, 40),
                onPressed: onClose,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.live_tv_rounded,
                      color: Colors.white24,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "l10n.streamInactiveTitle",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Gilroy',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.streamInactiveSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontFamily: 'Gilroy',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
