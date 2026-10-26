part of 'live_room_cubit.dart';

/// В какой стадии комната.
enum LiveRoomPhase {
  /// Берём токен и поднимаем соединения.
  connecting,

  /// Всё живо: видео идёт, сокет в комнате.
  live,

  /// Обрыв LiveKit, идёт переподключение с backoff.
  reconnecting,

  /// Эфир завершён — штатный исход, не ошибка.
  ended,

  /// Не удалось подключиться и повторы не помогли.
  failed,
}

/// Состояние комнаты эфира.
///
/// Одно состояние на всё, а не sealed-класс на каждую фазу: экрану нужны чат,
/// закреплённый товар, счётчик зрителей и стадия видео **одновременно**, и
/// при sealed-разбиении любой переход обнулял бы половину экрана.
class LiveRoomState extends Equatable {
  const LiveRoomState({
    required this.phase,
    this.stream,
    this.connection,
    this.chat = const [],
    this.pinnedProduct,
    this.viewerCount = 0,
    this.socketConnected = false,
    this.hasError = false,
  });

  factory LiveRoomState.initial(LiveStreamModel? preview) => LiveRoomState(
        phase: LiveRoomPhase.connecting,
        stream: preview,
        pinnedProduct: preview?.pinnedModel,
        viewerCount: preview?.viewerCount ?? 0,
      );

  final LiveRoomPhase phase;

  /// Детали эфира: заголовок, продавец, обложка. Может прийти заранее через
  /// `extra` маршрута, чтобы шапка не мигала.
  final LiveStreamModel? stream;

  /// url + token для LiveKit.
  final LiveConnection? connection;

  final List<LiveChatMessageModel> chat;

  /// Товар, который продавец показывает прямо сейчас. `null` — карточку не
  /// рисуем вовсе.
  final LiveProductCardModel? pinnedProduct;

  /// Считается по вебхукам LiveKit, поэтому отстаёт и не включает ведущего.
  final int viewerCount;

  final bool socketConnected;

  /// Сервер прислал `error`. Текст сырой и не локализуемый, поэтому наверх
  /// идёт только флаг — экран покажет свою строку.
  final bool hasError;

  bool get isLive => phase == LiveRoomPhase.live;
  bool get isEnded => phase == LiveRoomPhase.ended;
  bool get canChat => socketConnected && phase == LiveRoomPhase.live;

  LiveRoomState copyWith({
    LiveRoomPhase? phase,
    LiveStreamModel? stream,
    LiveConnection? connection,
    List<LiveChatMessageModel>? chat,
    LiveProductCardModel? pinnedProduct,
    int? viewerCount,
    bool? socketConnected,
    bool? hasError,
    bool clearError = false,
    // Без явного флага «снять пин» не выразить: `pinnedProduct ?? this.pinned`
    // всегда сохраняет старое значение. Прецедент — LiveState.clearStreamInfo
    // в кубите, который этот класс заменил.
    bool clearPinnedProduct = false,
  }) {
    return LiveRoomState(
      phase: phase ?? this.phase,
      stream: stream ?? this.stream,
      connection: connection ?? this.connection,
      chat: chat ?? this.chat,
      pinnedProduct:
          clearPinnedProduct ? null : (pinnedProduct ?? this.pinnedProduct),
      viewerCount: viewerCount ?? this.viewerCount,
      socketConnected: socketConnected ?? this.socketConnected,
      hasError: clearError ? false : (hasError ?? this.hasError),
    );
  }

  @override
  List<Object?> get props => [
        phase,
        stream?.id,
        stream?.title,
        stream?.seller?.id,
        connection?.token,
        // Длина плюс id последнего: пересобирать список целиком в props дорого,
        // а новое сообщение всегда меняет одно из двух.
        chat.length,
        chat.isEmpty ? null : chat.last.id,
        pinnedProduct?.id,
        viewerCount,
        socketConnected,
        hasError,
      ];
}
