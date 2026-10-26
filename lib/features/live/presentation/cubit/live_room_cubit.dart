import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/live_logger.dart';
import '../../data/datasources/live_services.dart';
import '../../data/datasources/live_socket_service.dart';
import '../../data/models/live_chat_message_model.dart';
import '../../data/models/live_product_card_model.dart';
import '../../data/models/live_stream_model.dart';
import '../../data/models/live_token_response.dart';
import '../../domain/repositories/live_repository.dart';

part 'live_room_state.dart';

/// Кто мы в этой комнате.
enum LiveRole {
  /// Смотрим. Токен берём из `POST /live/:id/token`.
  viewer,

  /// Ведём. Токен уже выдан в ответе `POST /live/start` — второй раз его
  /// получить неоткуда, зрительский тут не подойдёт.
  host,
}

/// Один эфир: токен LiveKit, сокет `/live`, чат, закреплённый товар, зрители.
///
/// Общий для зрителя и ведущего — иначе логику чата, пина и счётчика пришлось
/// бы держать в двух местах. Ведущий отличается только тем, что приносит свой
/// publisher-токен и может звать [showProduct] / [hideProduct].
///
/// Никогда не глобальный: внутри живут сокет и таймеры, привязанные к
/// конкретному `streamId`.
class LiveRoomCubit extends Cubit<LiveRoomState> {
  LiveRoomCubit({
    required this.streamId,
    this.role = LiveRole.viewer,
    LiveStreamModel? preview,
    LiveConnection? preAuthorized,
    LiveRepository? repository,
    LiveSocketService? socket,
  })  : _repo = repository ?? LiveServices(),
        _socket = socket ?? LiveSocketService(streamId: streamId),
        // ignore: prefer_initializing_formals — приватное поле
        _preAuthorized = preAuthorized,
        super(LiveRoomState.initial(preview));

  final int streamId;
  final LiveRole role;
  final LiveRepository _repo;
  final LiveSocketService _socket;
  final LiveConnection? _preAuthorized;

  static const _log = LiveLogger();

  /// Больше сообщений на экране всё равно не показать, а список растёт вечно.
  static const int maxChatBuffer = 100;

  /// Пока не ответили про TTL токенов и рейт-лимит `POST /live/:id/token`,
  /// первая пауза перед повтором заведомо щадящая.
  static const Duration reconnectFloor = Duration(seconds: 5);
  static const Duration reconnectCeiling = Duration(seconds: 30);
  static const int maxReconnectAttempts = 6;

  /// Сколько ждём `snapshot` после `joinStream`. Контракт не описывает, что
  /// сервер делает при входе в не-LIVE стрим, поэтому молчание трактуем как
  /// «эфир кончился», а не висим с вечным спиннером.
  static const Duration snapshotTimeout = Duration(seconds: 8);

  final List<StreamSubscription<dynamic>> _subs = [];
  Timer? _reconnectTimer;
  Timer? _snapshotTimer;
  int _reconnectAttempt = 0;
  bool _closed = false;

  /// Подключение: токен → сокет → LiveKit.
  Future<void> start() async {
    if (_closed) return;
    emit(state.copyWith(phase: LiveRoomPhase.connecting, clearError: true));

    final connection = await _resolveConnection();
    if (_closed || connection == null) return;

    emit(state.copyWith(
      phase: LiveRoomPhase.live,
      connection: connection,
      clearError: true,
    ));

    _bindSocket();
    await _socket.connect();
    _armSnapshotTimeout();
  }

  /// Где взять url+token. У ведущего он уже на руках, зритель идёт за ним в
  /// `POST /live/:id/token`.
  Future<LiveConnection?> _resolveConnection() async {
    final preAuthorized = _preAuthorized;
    if (preAuthorized != null && preAuthorized.isUsable) {
      // Заодно подтягиваем детали эфира, если их не передали, — шапке нужны
      // имя продавца и закреплённый товар.
      if (state.stream == null) unawaited(_loadStreamDetails());
      return preAuthorized;
    }

    final result = await _repo.getViewerToken(streamId);
    if (_closed) return null;
    switch (result) {
      case LiveViewerTokenOk(:final data):
        final stream = data.stream;
        if (stream != null) emit(state.copyWith(stream: stream));
        if (stream == null && state.stream == null) {
          unawaited(_loadStreamDetails());
        }
        return data.connection;
      case LiveViewerTokenNotLive():
        // Это не ошибка сети: эфир просто завершился.
        emit(state.copyWith(phase: LiveRoomPhase.ended));
        return null;
      case LiveViewerTokenUnauthorized():
        // Интерцептор appDio уже стёр токен и увёл на /auth — здесь молчим.
        emit(state.copyWith(phase: LiveRoomPhase.failed));
        return null;
      case LiveViewerTokenFailed():
        emit(state.copyWith(phase: LiveRoomPhase.failed));
        return null;
    }
  }

  Future<void> _loadStreamDetails() async {
    final result = await _repo.getStream(streamId);
    if (_closed) return;
    switch (result) {
      case LiveStreamLoaded(:final stream):
        emit(state.copyWith(
          stream: stream,
          // Пин из REST — чтобы карточка товара была на экране ещё до того,
          // как по сокету придёт snapshot.
          pinnedProduct: state.pinnedProduct ?? stream.pinnedModel,
        ));
      case LiveStreamNotFound():
        emit(state.copyWith(phase: LiveRoomPhase.ended));
      case LiveStreamFailed():
        break;
    }
  }

  void _bindSocket() {
    if (_subs.isNotEmpty) return;
    _subs.addAll([
      _socket.connection.listen((connected) {
        emit(state.copyWith(socketConnected: connected));
      }),
      _socket.snapshot.listen((snapshot) {
        _snapshotTimer?.cancel();
        // snapshot ВСЕГДА заменяет состояние целиком, а не дописывает: именно
        // это чинит всё, что клиент пропустил, пока был офлайн.
        emit(state.copyWith(
          chat: _trimChat(snapshot.chat),
          pinnedProduct: snapshot.pinnedProduct,
          clearPinnedProduct: snapshot.pinnedProduct == null,
          viewerCount: snapshot.viewerCount,
        ));
      }),
      _socket.chatMessage.listen((message) {
        emit(state.copyWith(chat: _trimChat([...state.chat, message])));
      }),
      _socket.productShown.listen((product) {
        emit(state.copyWith(pinnedProduct: product));
      }),
      _socket.productHidden.listen((_) {
        emit(state.copyWith(clearPinnedProduct: true));
      }),
      _socket.viewers.listen((count) {
        emit(state.copyWith(viewerCount: count));
      }),
      _socket.streamEnded.listen((_) {
        _log.event('stream:ended');
        _snapshotTimer?.cancel();
        _reconnectTimer?.cancel();
        emit(state.copyWith(
          phase: LiveRoomPhase.ended,
          clearPinnedProduct: true,
        ));
      }),
      _socket.socketError.listen((message) {
        // Наверх отдаём только флаг: у события есть лишь свободный текст без
        // машинного кода, локализовать его нельзя, поэтому экран покажет свою
        // общую строку, а сырое сообщение остаётся в логах.
        _log.error('socket error', message);
        emit(state.copyWith(hasError: true));
      }),
    ]);
  }

  void _armSnapshotTimeout() {
    _snapshotTimer?.cancel();
    _snapshotTimer = Timer(snapshotTimeout, () {
      if (_closed || state.phase != LiveRoomPhase.live) return;
      if (state.chat.isNotEmpty || state.viewerCount > 0) return;
      _log.warn('snapshot не пришёл за ${snapshotTimeout.inSeconds}s');
    });
  }

  List<LiveChatMessageModel> _trimChat(List<LiveChatMessageModel> messages) {
    if (messages.length <= maxChatBuffer) return messages;
    return messages.sublist(messages.length - maxChatBuffer);
  }

  /// Отправить сообщение. Возвращает причину отказа или `null`.
  LiveChatSendError? sendChat(String text) => _socket.sendChat(text);

  /// Показать товар зрителям (только ведущий).
  ///
  /// Оптимистично пин не ставим: рисуем его по серверному эху `product:shown`,
  /// иначе молча проглоченный emit выглядел бы как успех.
  void showProduct(int modelId) {
    if (role != LiveRole.host) return;
    _socket.showProduct(modelId);
  }

  void hideProduct() {
    if (role != LiveRole.host) return;
    _socket.hideProduct();
  }

  /// Обрыв соединения с LiveKit. Токен мог протухнуть (TTL в контракте не
  /// описан), поэтому запрашиваем новый и переподключаемся с backoff.
  void onLiveKitDisconnected() {
    if (_closed || state.phase == LiveRoomPhase.ended) return;
    if (role == LiveRole.host) {
      // Ведущему новый publisher-токен взять неоткуда: `/live/:id/token`
      // отдаёт зрительский. Только сообщаем экрану.
      emit(state.copyWith(phase: LiveRoomPhase.reconnecting));
      return;
    }
    if (_reconnectTimer?.isActive ?? false) return;

    if (_reconnectAttempt >= maxReconnectAttempts) {
      _log.warn('LiveKit: исчерпаны попытки переподключения');
      emit(state.copyWith(phase: LiveRoomPhase.failed));
      return;
    }

    final delay = _backoffDelay(_reconnectAttempt);
    _reconnectAttempt++;
    emit(state.copyWith(phase: LiveRoomPhase.reconnecting));
    _log.connect('LiveKit reconnect через ${delay.inSeconds}s',
        'попытка $_reconnectAttempt');
    _reconnectTimer = Timer(delay, _refreshConnection);
  }

  /// Успешно подписались на дорожку — обрывов больше нет, счётчик сбрасываем.
  void onLiveKitConnected() {
    _reconnectAttempt = 0;
    _reconnectTimer?.cancel();
    if (state.phase == LiveRoomPhase.reconnecting) {
      emit(state.copyWith(phase: LiveRoomPhase.live));
    }
  }

  Duration _backoffDelay(int attempt) {
    final base = reconnectFloor.inMilliseconds * pow(2, attempt).toInt();
    final capped = min(base, reconnectCeiling.inMilliseconds);
    // ±20% джиттера, чтобы после общего обрыва все клиенты не пришли разом.
    final jitter = (capped * 0.2 * (Random().nextDouble() * 2 - 1)).round();
    return Duration(milliseconds: max(1000, capped + jitter));
  }

  Future<void> _refreshConnection() async {
    if (_closed) return;
    final result = await _repo.getViewerToken(streamId);
    if (_closed) return;
    switch (result) {
      case LiveViewerTokenOk(:final data):
        emit(state.copyWith(
          phase: LiveRoomPhase.live,
          connection: data.connection,
        ));
        // После переподключения сокет мог пережить обрыв молча — просим свежий
        // snapshot, иначе чат так и останется на старом месте.
        _socket.rejoin();
      case LiveViewerTokenNotLive():
        emit(state.copyWith(phase: LiveRoomPhase.ended));
      case LiveViewerTokenUnauthorized():
      case LiveViewerTokenFailed():
        onLiveKitDisconnected();
    }
  }

  /// Возврат из фона. Сокет мог пересоединиться без нашего ведома, а он вне
  /// комнаты, пока не переотправлен `joinStream`.
  Future<void> onResumed() async {
    if (_closed || state.phase == LiveRoomPhase.ended) return;
    if (!_socket.isConnected) {
      await _socket.connect();
    } else {
      _socket.rejoin();
    }
  }

  /// Ручной повтор после исчерпанных попыток.
  Future<void> retry() async {
    _reconnectAttempt = 0;
    await start();
  }

  @override
  Future<void> close() async {
    _closed = true;
    _reconnectTimer?.cancel();
    _snapshotTimer?.cancel();
    for (final sub in _subs) {
      await sub.cancel();
    }
    await _socket.dispose();
    return super.close();
  }
}
