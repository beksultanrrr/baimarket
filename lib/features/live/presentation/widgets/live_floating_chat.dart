import 'package:flutter/material.dart';

import '../../data/models/live_chat_message_model.dart';
import '../../data/models/live_media.dart';

/// Плавающие сообщения чата без фона-контейнера — как в макете frame 11.
///
/// Поведение ленты повторяет инстаграмный лайв:
///  * новые сообщения приходят снизу, лента сама остаётся прижатой к низу;
///  * если отлистать вверх и читать историю, позиция не сбивается —
///    подъехавшее сообщение не дёргает список (это даёт `reverse: true`);
///  * верхний край растворяется — старые сообщения уходят в прозрачность,
///    а не обрезаются ножом;
///  * каждое новое сообщение всплывает: короткий fade со сдвигом снизу.
///
/// Высоту задаёт родитель ([Expanded] на экране зрителя, [SizedBox] у
/// ведущего) — виджет занимает всё, что ему дали.
class LiveFloatingChat extends StatefulWidget {
  const LiveFloatingChat({super.key, required this.messages});
  final List<LiveChatMessageModel> messages;

  @override
  State<LiveFloatingChat> createState() => _LiveFloatingChatState();
}

class _LiveFloatingChatState extends State<LiveFloatingChat> {
  /// id сообщений, которым ещё предстоит всплыть.
  ///
  /// Набор считается в [didUpdateWidget], а не в `itemBuilder`: билдер
  /// вызывается по нескольку раз за кадр (замеры, пересоздание улетевших за
  /// экран строк), и пометка «уже показано» прямо в нём то съедала анимацию,
  /// то проигрывала её заново при возврате к сообщению.
  final Set<int> _pending = <int>{};

  /// Что показывали в прошлый раз — для поиска добавившихся.
  ///
  /// Заполняется в [initState], а не `late`-инициализатором: ленивое поле
  /// первый раз читается уже внутри [didUpdateWidget], где `widget` — новый,
  /// и добавившееся сообщение сразу попадало в «известные», так и не всплыв.
  late Set<int> _known;

  @override
  void initState() {
    super.initState();
    // Первый кадр показываем без анимации: всплывать должны только те
    // сообщения, что пришли уже при открытом эфире.
    _known = widget.messages.map((m) => m.id).toSet();
  }

  @override
  void didUpdateWidget(covariant LiveFloatingChat oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ids = widget.messages.map((m) => m.id).toSet();
    _pending.addAll(ids.difference(_known));
    _known = ids;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) return const SizedBox.shrink();

    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        // Прозрачно вверху → плотно к середине: растворяется только «хвост»
        // истории, свежие сообщения внизу читаются в полную силу.
        colors: [Colors.transparent, Colors.white],
        stops: [0.0, 0.28],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        reverse: true,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.messages.length,
        // reverse рисует с конца списка, поэтому идём от последнего сообщения.
        itemBuilder: (_, i) {
          final message = widget.messages[widget.messages.length - 1 - i];
          return _ChatRow(
            key: ValueKey(message.id),
            message: message,
            animate: _pending.contains(message.id),
            // Снимаем пометку после проигрывания, иначе сообщение всплывало
            // бы снова каждый раз, когда возвращается в зону видимости.
            onAppeared: () => _pending.remove(message.id),
          );
        },
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({
    super.key,
    required this.message,
    this.animate = false,
    this.onAppeared,
  });
  final LiveChatMessageModel message;

  /// Проигрывать ли всплытие. Только для сообщений, которых ещё не видели.
  final bool animate;

  /// Вызывается, когда всплытие доиграло.
  final VoidCallback? onAppeared;

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

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.fromLTRB(0, 7, 15, 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38.4,
            height: 38.4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            alignment: Alignment.center,
            child: _avatar.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      _avatar,
                      width: 38.4,
                      height: 38.4,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _Initials(text: _initials),
                    ),
                  )
                : _Initials(text: _initials),
          ),
          const SizedBox(width: 11.6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.fullName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  message.isDeleted ? 'Сообщение удалено' : message.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: message.isDeleted
                        ? Colors.redAccent
                        : Colors.white.withValues(alpha: 0.8),
                    fontStyle: message.isDeleted
                        ? FontStyle.italic
                        : FontStyle.normal,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!animate) return row;
    return _AppearAnimation(onDone: onAppeared, child: row);
  }
}

/// Всплытие нового сообщения: 220 мс fade со сдвигом на 12pt снизу.
class _AppearAnimation extends StatefulWidget {
  const _AppearAnimation({required this.child, this.onDone});
  final Widget child;
  final VoidCallback? onDone;

  @override
  State<_AppearAnimation> createState() => _AppearAnimationState();
}

class _AppearAnimationState extends State<_AppearAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward().whenComplete(() => widget.onDone?.call());

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Gilroy',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}
