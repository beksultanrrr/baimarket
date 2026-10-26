import '../../data/models/live_chat_message_model.dart';
import '../../data/models/live_stream_model.dart';
import '../../data/models/live_token_response.dart';

/// Результат `GET /live` и `GET /live/my`.
sealed class LiveListResult {
  const LiveListResult();
}

class LiveListLoaded extends LiveListResult {
  const LiveListLoaded(this.streams);
  final List<LiveStreamModel> streams;
}

class LiveListFailed extends LiveListResult {
  const LiveListFailed();
}

/// Результат `GET /live/:id`.
sealed class LiveStreamResult {
  const LiveStreamResult();
}

class LiveStreamLoaded extends LiveStreamResult {
  const LiveStreamLoaded(this.stream);
  final LiveStreamModel stream;
}

/// Эфира нет — его могли удалить между открытием ленты и тапом по карточке.
class LiveStreamNotFound extends LiveStreamResult {
  const LiveStreamNotFound();
}

class LiveStreamFailed extends LiveStreamResult {
  const LiveStreamFailed();
}

/// Результат `POST /live/start`.
///
/// Коды здесь принципиально не схлопываются в общий «не получилось»: каждый
/// ведёт к своему экрану. Отдельной ручки «можно ли мне стримить» в контракте
/// нет — именно этот ответ и есть проверка прав.
sealed class LiveStartResult {
  const LiveStartResult();
}

class LiveStartOk extends LiveStartResult {
  const LiveStartOk(this.data);
  final LiveStartResponse data;
}

/// 403 — продавцу не выдан доступ к эфирам либо аккаунт отключён.
/// Показываем «Эфиры недоступны, обратитесь в поддержку».
class LiveStartForbidden extends LiveStartResult {
  const LiveStartForbidden();
}

/// 409 — у продавца **уже идёт** эфир. Второй создавать нельзя, возвращаем его
/// в [streamId].
class LiveStartConflict extends LiveStartResult {
  const LiveStartConflict({required this.streamId, this.message});
  final int? streamId;
  final String? message;
}

/// 401 — токен протух. Навигацию отсюда не делаем: интерцептор `appDio` уже
/// стёр токен и увёл на `/auth`.
class LiveStartUnauthorized extends LiveStartResult {
  const LiveStartUnauthorized();
}

class LiveStartFailed extends LiveStartResult {
  const LiveStartFailed();
}

/// Результат `POST /live/:id/token` — токен зрителя.
sealed class LiveViewerTokenResult {
  const LiveViewerTokenResult();
}

class LiveViewerTokenOk extends LiveViewerTokenResult {
  const LiveViewerTokenOk(this.data);
  final LiveViewerTokenResponse data;
}

/// 404 — эфир не в статусе LIVE. Это «эфир завершён», а не ошибка сети, и
/// экран должен сказать именно так.
class LiveViewerTokenNotLive extends LiveViewerTokenResult {
  const LiveViewerTokenNotLive();
}

class LiveViewerTokenUnauthorized extends LiveViewerTokenResult {
  const LiveViewerTokenUnauthorized();
}

class LiveViewerTokenFailed extends LiveViewerTokenResult {
  const LiveViewerTokenFailed();
}

/// Результат `POST /live/:id/stop`.
sealed class LiveStopResult {
  const LiveStopResult();
}

class LiveStopOk extends LiveStopResult {
  const LiveStopOk(this.stream);
  final LiveStreamModel stream;
}

class LiveStopFailed extends LiveStopResult {
  const LiveStopFailed();
}

/// Результат `GET /live/:id/chat`.
sealed class LiveChatHistoryResult {
  const LiveChatHistoryResult();
}

class LiveChatHistoryLoaded extends LiveChatHistoryResult {
  const LiveChatHistoryLoaded(this.messages);
  final List<LiveChatMessageModel> messages;
}

class LiveChatHistoryFailed extends LiveChatHistoryResult {
  const LiveChatHistoryFailed();
}

abstract class LiveRepository {
  /// `GET /live` — идущие эфиры (status=LIVE), с `seller` и `pinnedModel`.
  Future<LiveListResult> getLiveStreams();

  /// `GET /live/my` — мои эфиры: активные и история.
  Future<LiveListResult> getMyStreams();

  /// `GET /live/:id`
  Future<LiveStreamResult> getStream(int id);

  /// `POST /live/start` — роль SELLER плюс выданный админом доступ к эфирам.
  Future<LiveStartResult> startStream({required String title, String? coverUrl});

  /// `POST /live/:id/stop` — завершить свой эфир, комната LiveKit закроется.
  Future<LiveStopResult> stopStream(int id);

  /// `POST /live/:id/token` — токен зрителя (только пока эфир идёт).
  Future<LiveViewerTokenResult> getViewerToken(int id);

  /// `GET /live/:id/chat` — последние 50 сообщений по возрастанию.
  ///
  /// Обычно не нужен: тот же список приходит в `snapshot` по сокету. Полезен
  /// на холодном старте, когда сокет ещё не поднялся.
  Future<LiveChatHistoryResult> getChatHistory(int id);
}
