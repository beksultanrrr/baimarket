import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/live_chat_message_model.dart';
import '../../data/models/live_media.dart';
import '../cubit/live_room_cubit.dart';
import 'sheet_close_button.dart';
import 'live_shopping_scope.dart';

/// Открывает bottom-sheet «Комментарий» (frames 24/25) с лентой сообщений
/// и input-ом снизу. Sheet скейлится через DraggableScrollableSheet — при
/// открытой клавиатуре нижняя часть с input + send-button прижимается
/// к клавиатуре.
Future<void> showLiveCommentsSheet({
  required BuildContext context,
  required LiveRoomCubit cubit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    routeSettings: const RouteSettings(name: kLiveSheetRouteName),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (sheetCtx) {
      return BlocProvider.value(
        value: cubit,
        child: const _LiveCommentsSheet(),
      );
    },
  );
}

class _LiveCommentsSheet extends StatefulWidget {
  const _LiveCommentsSheet();

  @override
  State<_LiveCommentsSheet> createState() => _LiveCommentsSheetState();
}

class _LiveCommentsSheetState extends State<_LiveCommentsSheet> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final t = _input.text.trim();
    if (t.isEmpty) return;
    context.read<LiveRoomCubit>().sendChat(t);
    _input.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Комментарий',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      SheetCloseButton(onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocBuilder<LiveRoomCubit, LiveRoomState>(
                    builder: (context, state) {
                      final messages = state.chat;
                      if (messages.isEmpty) {
                        return const Center(
                          child: Text(
                            'Сообщений пока нет',
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 14,
                              color: Color(0xFF8C8C8C),
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: _scrollCtrl,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                        itemCount: messages.length,
                        itemBuilder: (_, i) =>
                            _CommentRow(message: messages[i]),
                      );
                    },
                  ),
                ),
                _InputRow(
                  controller: _input,
                  focusNode: _focus,
                  onSend: _send,
                ),
                SizedBox(height: mq.padding.bottom),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.message});
  final LiveChatMessageModel message;

  /// avatarUrl — имя файла в MinIO, а не готовая ссылка.
  String get _avatar => liveAvatarUrl(message.avatarUrl);

  String get _initials {
    final n = (message.fullName ?? '').trim();
    if (n.isEmpty) return '?';
    return n
        .split(RegExp(r'\s+'))
        .take(2)
        .map((p) => p.isEmpty ? '' : p[0])
        .join()
        .toUpperCase();
  }

  String _ago(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'только что';
    if (diff.inHours < 1) return '${diff.inMinutes}мин';
    if (diff.inDays < 1) return '${diff.inHours}ч';
    return '${diff.inDays}д';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEFEFEF),
            ),
            alignment: Alignment.center,
            child: ClipOval(
              child: _avatar.isNotEmpty
                  ? Image.network(
                      _avatar,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _Initials(text: _initials),
                    )
                  : _Initials(text: _initials),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.fullName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.isDeleted ? 'Сообщение удалено' : message.message,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: message.isDeleted
                        ? Colors.redAccent
                        : Colors.black,
                    fontStyle: message.isDeleted
                        ? FontStyle.italic
                        : FontStyle.normal,
                    height: 1.25,
                  ),
                ),
                if (message.createdAtDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  _ago(message.createdAtDate!),
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFB0B0B0),
                  ),
                ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6E6E6E),
        ),
      ),
    );
  }
}

class _InputRow extends StatefulWidget {
  const _InputRow({
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  @override
  State<_InputRow> createState() => _InputRowState();
}

class _InputRowState extends State<_InputRow> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode.hasFocus;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: const Color(0xFFEFEFEF),
            width: isFocused ? 0 : 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEFEFEF),
            ),
            child: const Icon(
              Icons.person,
              size: 22,
              color: Color(0xFF8C8C8C),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEFEFEF),
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                onSubmitted: (_) => widget.onSend(),
                textInputAction: TextInputAction.send,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  height: 1.2,
                ),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  hintText: 'Введите комментарии...',
                  hintStyle: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8C8C8C),
                  ),
                ),
              ),
            ),
          ),
          if (_hasText) ...[
            const SizedBox(width: 10),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(40, 40),
              onPressed: widget.onSend,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEC1B6E),
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
