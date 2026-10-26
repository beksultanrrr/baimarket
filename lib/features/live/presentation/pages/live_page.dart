import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../data/datasources/live_socket_service.dart';
import '../../data/models/live_media.dart';
import '../../data/models/live_stream_model.dart';
import '../cubit/live_room_cubit.dart';
import '../widgets/live_action_rail.dart';
import '../widgets/live_comments_sheet.dart';
import '../widgets/live_floating_chat.dart';
import '../widgets/live_gifts_sheet.dart';
import '../widgets/live_pinned_product_card.dart';
import '../widgets/live_shopping_scope.dart';
import '../widgets/livekit_player.dart';

/// Экран зрителя.
///
/// Три канала работают одновременно: LiveKit несёт видео и звук, наш сокет
/// `/live` — чат, закреплённый товар и счётчик зрителей, REST — токен. Подключение
/// только к LiveKit было бы самой частой ошибкой: видео идёт, а всё остальное
/// пустое.
class LivePage extends StatefulWidget {
  const LivePage({super.key, required this.streamId, this.preview});

  final int streamId;

  /// Данные из ленты, если пришли через `extra`. Нужны только чтобы шапка не
  /// мигала, пока грузится `GET /live/:id`.
  final LiveStreamModel? preview;

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> with WidgetsBindingObserver {
  late final LiveRoomCubit _cubit;
  final FocusNode _inputFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit = LiveRoomCubit(
      streamId: widget.streamId,
      preview: widget.preview,
    )..start();
    // Пока открыт эфир, покупка идёт шитами поверх него. Регистрация делает
    // контроллер доступным виджетам над роутером — плашке корзины и разбору
    // 401 в интерцепторе.
    LiveShoppingController.register(LiveShoppingController());
  }

  @override
  void dispose() {
    LiveShoppingController.unregister();
    WidgetsBinding.instance.removeObserver(this);
    _inputFocus.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Сокет мог молча пересоединиться в фоне, а вне комнаты события не идут.
    if (state == AppLifecycleState.resumed) _cubit.onResumed();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<LiveRoomCubit, LiveRoomState>(
        builder: (context, state) {
          if (state.phase == LiveRoomPhase.ended) {
            return _StreamEndedView(onClose: () => _close(context));
          }
          if (state.phase == LiveRoomPhase.failed) {
            return _StreamFailedView(
              onRetry: () => context.read<LiveRoomCubit>().retry(),
              onClose: () => _close(context),
            );
          }
          return _ActiveStreamView(
            state: state,
            inputFocus: _inputFocus,
            onClose: () => _close(context),
          );
        },
      ),
    );
  }

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/streams'); // live-nav-ok: сам выход из эфира
    }
  }
}

class _ActiveStreamView extends StatelessWidget {
  const _ActiveStreamView({
    required this.state,
    required this.inputFocus,
    required this.onClose,
  });

  final LiveRoomState state;
  final FocusNode inputFocus;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboardOpen = mq.viewInsets.bottom > 0;
    final cubit = context.read<LiveRoomCubit>();
    final stream = state.stream;
    final pinned = state.pinnedProduct;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _VideoLayer(state: state),
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
                  title: stream?.title ?? '',
                  sellerName: stream?.seller?.displayName ?? '',
                  avatarUrl: liveAvatarUrl(stream?.seller?.avatarUrl),
                  viewerCount: state.viewerCount,
                  onClose: onClose,
                ),
                if (state.phase == LiveRoomPhase.reconnecting)
                  const _ReconnectingBanner(),
                // Витрина продавца, который сейчас вещает. Без sellerId её
                // открыть неоткуда, поэтому кнопки просто нет.
                if (!keyboardOpen && stream?.seller?.id != null) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _ProductsButton(
                        onTap: () => showLiveGiftsSheet(
                          context: context,
                          sellerId: stream!.seller!.id,
                          pinnedProductId: pinned?.id,
                        ),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: LiveFloatingChat(messages: state.chat)),
                      if (!keyboardOpen) ...[
                        const SizedBox(width: 8),
                        LiveActionRail(
                          cartCount: _cartItemsCount(context),
                          messageCount: state.chat.length,
                          onCartTap: () => openLiveCartSheet(context),
                          onMessageTap: () => showLiveCommentsSheet(
                            context: context,
                            cubit: cubit,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Закреплённого товара нет — не рисуем ничего. Забить слот
                // посторонней коллекцией и было прошлым багом.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SizeTransition(
                      sizeFactor: animation,
                      alignment: AlignmentDirectional.topCenter,
                      child: child,
                    ),
                  ),
                  child: pinned == null
                      ? const SizedBox.shrink(key: ValueKey('no-pinned'))
                      : LivePinnedProductCard(
                          key: ValueKey('pinned-${pinned.id}'),
                          product: pinned,
                        ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: _CommentInputRow(
                    focusNode: inputFocus,
                    canChat: state.canChat,
                    onSend: (text) => _send(context, text),
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

  void _send(BuildContext context, String text) {
    final l10n = AppLocalizations.of(context)!;
    final error = context.read<LiveRoomCubit>().sendChat(text);
    if (error == null) return;
    final message = switch (error) {
      LiveChatSendError.empty => null,
      LiveChatSendError.tooLong => l10n.streamChatTooLong,
      LiveChatSendError.rateLimited => l10n.streamChatRateLimited,
      LiveChatSendError.disconnected => l10n.streamConnectionLost,
    };
    if (message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

/// Видеослой. Пока токена нет — заглушка; YouTube-фоллбэка больше не
/// существует, у контракта ровно один транспорт.
class _VideoLayer extends StatelessWidget {
  const _VideoLayer({required this.state});
  final LiveRoomState state;

  @override
  Widget build(BuildContext context) {
    final connection = state.connection;
    if (connection == null || !connection.isUsable) {
      return const ColoredBox(
        color: Color(0xFF1E1E1E),
        child: Center(
          child: CircularProgressIndicator(color: Colors.white24, strokeWidth: 2),
        ),
      );
    }
    return LiveKitPlayer(
      // Токен меняется при обновлении — по этому ключу виджет пересоздаёт
      // соединение вместо того, чтобы держать мёртвое.
      key: ValueKey(connection.token),
      url: connection.url,
      token: connection.token,
      roomName: state.stream?.roomName,
      onConnected: () => context.read<LiveRoomCubit>().onLiveKitConnected(),
      onDisconnected: () =>
          context.read<LiveRoomCubit>().onLiveKitDisconnected(),
    );
  }
}

class _ReconnectingBanner extends StatelessWidget {
  const _ReconnectingBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.streamReconnecting,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveHeader extends StatelessWidget {
  const _LiveHeader({
    required this.title,
    required this.sellerName,
    required this.avatarUrl,
    required this.viewerCount,
    required this.onClose,
  });

  final String title;
  final String sellerName;
  final String avatarUrl;
  final int viewerCount;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final caption = sellerName.isNotEmpty ? sellerName : title;
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
              child: avatarUrl.isNotEmpty
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Image.asset('assets/images/person.png'),
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
                  caption,
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
                        letterSpacing: 0.22,
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
            minimumSize: const Size(30, 30),
            onPressed: onClose,
            child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}

/// Розовая плашка LIVE. Публичная — её же использует шапка ведущего.
class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key});

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
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset('assets/icons/stream/live_sun.svg',
              width: 16, height: 16),
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

/// Кнопка «Товары в стриме» под шапкой.
class _ProductsButton extends StatelessWidget {
  const _ProductsButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/stream/action_bag.svg',
              width: 14,
              height: 14,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.streamProductsTitle,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
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

/// Суммарное количество товаров в корзине.
int _cartItemsCount(BuildContext context) {
  context.watch<CartCubit>();
  return context.read<CartCubit>().itemsCount;
}

/// Эфир завершён — штатный исход, а не ошибка сети.
class _StreamEndedView extends StatelessWidget {
  const _StreamEndedView({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _MessageScaffold(
      icon: Icons.live_tv_rounded,
      title: l10n.streamEndedTitle,
      subtitle: l10n.streamEndedSubtitle,
      onClose: onClose,
    );
  }
}

class _StreamFailedView extends StatelessWidget {
  const _StreamFailedView({required this.onRetry, required this.onClose});
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _MessageScaffold(
      icon: Icons.error_outline_rounded,
      title: l10n.streamErrorGeneric,
      subtitle: l10n.streamConnectionLost,
      onClose: onClose,
      action: CupertinoButton(
        onPressed: onRetry,
        child: Text(
          l10n.streamRetry,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _MessageScaffold extends StatelessWidget {
  const _MessageScaffold({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onClose,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onClose;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
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
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white24, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      title,
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
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontFamily: 'Gilroy',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (action != null) ...[
                      const SizedBox(height: 12),
                      action!,
                    ],
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
