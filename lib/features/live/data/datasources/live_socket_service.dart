import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/secure_token_storage.dart';
import '../../../../core/services/live_logger.dart';
import '../../../../core/urls.dart';
import '../models/live_chat_message_model.dart';
import '../models/live_product_card_model.dart';

/// Адрес namespace `/live`.
///
/// `mainUrl` заканчивается слэшем, поэтому просто склеить строки нельзя —
/// получится `//live`. socket.io берёт namespace из пути URL
/// (`io.socket(parsed.path)`), так что путь должен быть ровно `/live`.
String liveNamespaceUrl([String base = mainUrl]) {
  final trimmed = base.endsWith('/')
      ? base.substring(0, base.length - 1)
      : base;
  return '$trimmed/live';
}

/// Начальное состояние комнаты, приходящее в ответ на `joinStream`.
class LiveSnapshot {
  const LiveSnapshot({
    required this.chat,
    required this.pinnedProduct,
    required this.viewerCount,
  });

  final List<LiveChatMessageModel> chat;
  final LiveProductCardModel? pinnedProduct;
  final int viewerCount;
}

/// Сокет одного эфира: namespace `/live`, комната `stream-<streamId>`.
///
/// Один сокет на эфир, а не общий переиспользуемый. Так токен привязывается к
/// handshake именно этого подключения, время жизни сокета совпадает со
/// временем жизни экрана (значит `dispose` тривиально корректен), и чат одного
/// эфира физически не может протечь в буфер другого.
///
/// Заменяет `core/services/live_socket_service.dart`, который жил в корневом
/// namespace и слушал события старого контракта (`streamStarted`,
/// `chatHistory`, `newMessage`) — ни одного из них на сервере больше нет.
class LiveSocketService {
  LiveSocketService({required this.streamId, LiveLogger? logger})
      : _log = logger ?? const LiveLogger();

  final int streamId;
  final LiveLogger _log;

  /// Лимит длины сообщения и окно рейт-лимита — как в контракте. Держим их и
  /// на клиенте, чтобы не ловить серверный `error` на очевидных случаях.
  static const int maxMessageLength = 500;
  static const int maxMessagesPerMinute = 20;
  static const Duration rateLimitWindow = Duration(minutes: 1);

  io.Socket? _socket;
  Future<bool>? _connecting;
  bool _disposed = false;

  /// Локальное ведро под рейт-лимит: отметки времени отправленных сообщений.
  final List<DateTime> _sentAt = [];

  final _connection = StreamController<bool>.broadcast();
  final _snapshot = StreamController<LiveSnapshot>.broadcast();
  final _chatMessage = StreamController<LiveChatMessageModel>.broadcast();
  final _productShown = StreamController<LiveProductCardModel>.broadcast();
  final _productHidden = StreamController<void>.broadcast();
  final _viewers = StreamController<int>.broadcast();
  final _streamEnded = StreamController<void>.broadcast();
  final _socketError = StreamController<String>.broadcast();

  Stream<bool> get connection => _connection.stream;
  Stream<LiveSnapshot> get snapshot => _snapshot.stream;
  Stream<LiveChatMessageModel> get chatMessage => _chatMessage.stream;
  Stream<LiveProductCardModel> get productShown => _productShown.stream;
  Stream<void> get productHidden => _productHidden.stream;
  Stream<int> get viewers => _viewers.stream;
  Stream<void> get streamEnded => _streamEnded.stream;
  Stream<String> get socketError => _socketError.stream;

  bool get isConnected => _socket?.connected ?? false;

  /// Поднимает соединение. Идемпотентно: повторные вызовы при уже открытом или
  /// ещё открывающемся сокете возвращают тот же in-flight Future.
  Future<bool> connect() async {
    if (_disposed) return false;
    if (_socket?.connected ?? false) return true;
    final inFlight = _connecting;
    if (inFlight != null) return inFlight;

    final future = _doConnect();
    _connecting = future;
    try {
      return await future;
    } finally {
      _connecting = null;
    }
  }

  Future<bool> _doConnect() async {
    final url = liveNamespaceUrl();
    _log.connect('opening /live socket', '$url stream=$streamId');

    final socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          // Каждый эфир — своё соединение, иначе socket.io переиспользует
          // менеджер и с ним старый handshake.
          .enableForceNew()
          // Не setAuth: функцию socket.io зовёт заново на КАЖДОМ открытии,
          // поэтому после реконнекта в handshake уходит свежий токен, а не
          // тот, что был прочитан при создании сокета.
          .setAuthFn((callback) async {
            final token = await getAuthToken();
            callback({'token': token ?? ''});
          })
          .build(),
    );

    final firstResponse = Completer<bool>();
    void completeOnce(bool ok) {
      if (!firstResponse.isCompleted) firstResponse.complete(ok);
    }

    socket
      ..on('connect', (_) {
        _log.connect('connected', 'sid=${socket.id}');
        _connection.add(true);
        // Обязательный повтор: событие приходит и на первом хендшейке, и на
        // каждом реконнекте. Без него после обрыва клиент остаётся вне комнаты
        // и события просто перестают приходить.
        _emitJoin();
        completeOnce(true);
      })
      ..on('disconnect', (reason) {
        _log.connect('disconnected', reason);
        _connection.add(false);
      })
      ..on('connect_error', (err) {
        _log.error('connect_error', err);
        completeOnce(false);
      })
      ..on('snapshot', (data) => _guard('snapshot', () {
            if (data is! Map) return;
            final payload = Map<String, dynamic>.from(data);
            final chat = <LiveChatMessageModel>[];
            final rawChat = payload['chat'];
            if (rawChat is List) {
              for (final item in rawChat) {
                if (item is! Map) continue;
                chat.add(
                  LiveChatMessageModel.fromJson(Map<String, dynamic>.from(item)),
                );
              }
            }
            final rawPinned = payload['pinnedProduct'];
            _snapshot.add(
              LiveSnapshot(
                chat: chat,
                pinnedProduct: rawPinned is Map
                    ? LiveProductCardModel.fromJson(
                        Map<String, dynamic>.from(rawPinned),
                      )
                    : null,
                viewerCount: _viewersFrom(payload),
              ),
            );
          }))
      ..on('chat:new', (data) => _guard('chat:new', () {
            if (data is! Map) return;
            _chatMessage.add(
              LiveChatMessageModel.fromJson(Map<String, dynamic>.from(data)),
            );
          }))
      ..on('product:shown', (data) => _guard('product:shown', () {
            if (data is! Map) return;
            _productShown.add(
              LiveProductCardModel.fromJson(Map<String, dynamic>.from(data)),
            );
          }))
      ..on('product:hidden', (_) => _guard('product:hidden', () {
            _productHidden.add(null);
          }))
      ..on('viewers', (data) => _guard('viewers', () {
            final count = data is Map
                ? _viewersFrom(Map<String, dynamic>.from(data))
                : _asInt(data);
            _log.event('viewers', '$count (raw: $data)');
            _viewers.add(count);
          }))
      ..on('stream:ended', (_) => _guard('stream:ended', () {
            _streamEnded.add(null);
          }))
      ..on('error', (data) => _guard('error', () {
            final message = data is Map ? '${data['message'] ?? ''}' : '$data';
            // Контракт отдаёт только свободный текст, без машинного кода, —
            // локализовать его нельзя. Отдаём наверх для лога, а пользователю
            // экран покажет свою общую строку.
            _log.error('server error event', message);
            _socketError.add(message);
          }));

    _socket = socket;
    socket.connect();

    return firstResponse.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _log.warn('connect timeout — socket остаётся, попробуем позже');
        return false;
      },
    );
  }

  /// Каждое входящее событие разбирается в своём try/catch: кривой payload
  /// одного события не должен ронять зону, в которой живёт весь сокет.
  void _guard(String event, void Function() body) {
    try {
      body();
    } catch (e, st) {
      _log.error('failed to handle $event', e.toString(), e, st);
    }
  }

  void _emitJoin() {
    final s = _socket;
    if (s == null || !s.connected) return;
    _log.emit('joinStream', 'stream=$streamId');
    s.emit('joinStream', {'streamId': streamId});
  }

  /// Повторно войти в комнату. Нужен после возврата из фона, когда сокет мог
  /// молча пересоединиться.
  void rejoin() => _emitJoin();

  /// Отправка сообщения в чат.
  ///
  /// Возвращает причину отказа или `null`, если сообщение ушло. Отдельный тип
  /// не заводим: вызывающему нужно только выбрать текст ошибки.
  LiveChatSendError? sendChat(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return LiveChatSendError.empty;
    if (trimmed.length > maxMessageLength) return LiveChatSendError.tooLong;

    final s = _socket;
    if (s == null || !s.connected) {
      // Отдать socket.io в буфер нельзя: он сливает sendBuffer в onconnect
      // ДО события `connect`, то есть до нашего joinStream, и сообщение уйдёт,
      // когда мы ещё не в комнате.
      _log.warn('sendChat отклонён — сокет не подключён');
      return LiveChatSendError.disconnected;
    }

    final now = DateTime.now();
    _sentAt.removeWhere((t) => now.difference(t) > rateLimitWindow);
    if (_sentAt.length >= maxMessagesPerMinute) {
      _log.warn('sendChat отклонён — локальный рейт-лимит');
      return LiveChatSendError.rateLimited;
    }
    _sentAt.add(now);

    _log.emit('chat:send', trimmed);
    s.emit('chat:send', {'streamId': streamId, 'message': trimmed});
    return null;
  }

  /// Показать товар зрителям. Только владелец-продавец, иначе прилетит `error`.
  void showProduct(int modelId) {
    final s = _socket;
    if (s == null || !s.connected) return;
    _log.emit('product:show', 'model=$modelId');
    s.emit('product:show', {'streamId': streamId, 'modelId': modelId});
  }

  /// Убрать товар с экрана. Только владелец-продавец.
  void hideProduct() {
    final s = _socket;
    if (s == null || !s.connected) return;
    _log.emit('product:hide');
    s.emit('product:hide', {'streamId': streamId});
  }

  Future<void> disconnect() async {
    final s = _socket;
    _socket = null;
    if (s == null) return;
    _log.connect('leaving stream', 'stream=$streamId');
    if (s.connected) s.emit('leaveStream', {'streamId': streamId});
    s.disconnect();
    s.dispose();
    if (!_connection.isClosed) _connection.add(false);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await disconnect();
    await _connection.close();
    await _snapshot.close();
    await _chatMessage.close();
    await _productShown.close();
    await _productHidden.close();
    await _viewers.close();
    await _streamEnded.close();
    await _socketError.close();
  }

  int _asInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    return int.tryParse('$raw') ?? 0;
  }

  /// Достаёт число зрителей из payload.
  ///
  /// Ключ ищем среди нескольких вариантов: снапшот и событие `viewers`
  /// приходят от разных обработчиков сервера и называют поле по-разному
  /// (`viewerCount` / `count` / `viewers`). Раньше каждый разбирался жёстко по
  /// одному имени, и при расхождении счётчик молча оставался нулём.
  int _viewersFrom(Map<String, dynamic> payload) {
    for (final key in const ['viewerCount', 'count', 'viewers', 'viewersCount']) {
      final raw = payload[key];
      if (raw == null) continue;
      if (raw is num) return raw.round();
      final parsed = int.tryParse('$raw');
      if (parsed != null) return parsed;
    }
    return 0;
  }
}

/// Почему сообщение не ушло. Каждому варианту соответствует своя строка в UI.
enum LiveChatSendError { empty, tooLong, disconnected, rateLimited }
