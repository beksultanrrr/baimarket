import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/live_services.dart';
import '../../data/models/live_stream_model.dart';
import '../../domain/repositories/live_repository.dart';

part 'live_host_state.dart';

/// Старт, публикация и завершение своего эфира.
///
/// Намеренно тонкий: чат, закреплённый товар и счётчик зрителей ведёт
/// `LiveRoomCubit(role: host)` — тот же код, что у зрителя. Дублировать его
/// здесь означало бы поддерживать две расходящиеся реализации одного и того
/// же сокета.
///
/// **Регистрируется глобально в `main.dart` и существует в одном экземпляре.**
/// «Идёт ли у меня эфир» читают два экрана сразу: вкладка «Эфиры» (что писать
/// на кнопке) и экран ведущего (который этот эфир завершает). Пока у них были свои
/// кубиты, `stop()` гасил эфир только на экране ведущего, а на вкладке кнопка
/// так и оставалась «Вернуться в свой эфир».
class LiveHostCubit extends Cubit<LiveHostState> {
  LiveHostCubit({LiveRepository? repository})
      : _repo = repository ?? LiveServices(),
        super(const LiveHostState());

  final LiveRepository _repo;

  /// Проверить, не идёт ли у меня эфир прямо сейчас.
  ///
  /// Любой не-успех — это «активного эфира нет», а не ошибка: вкладку «Эфиры»
  /// открывают все, включая гостей и обычных покупателей, и показывать им
  /// ошибку не за что.
  Future<void> loadMyActiveStream() async {
    final result = await _repo.getMyStreams();
    if (isClosed) return;
    if (result is! LiveListLoaded) {
      emit(state.copyWith(clearActive: true));
      return;
    }
    LiveStreamModel? active;
    for (final stream in result.streams) {
      if (stream.isLive) {
        active = stream;
        break;
      }
    }
    emit(state.copyWith(activeStream: active, clearActive: active == null));
  }

  /// `POST /live/start`.
  ///
  /// Разбор ответа и есть проверка прав: отдельной ручки «можно ли мне
  /// стримить» в контракте нет.
  Future<LiveStartResult> start({
    required String title,
    String? coverUrl,
  }) async {
    emit(state.copyWith(status: LiveHostStatus.starting, clearOutcome: true));
    final result = await _repo.startStream(title: title, coverUrl: coverUrl);
    if (isClosed) return result;

    switch (result) {
      case LiveStartOk(:final data):
        emit(state.copyWith(
          status: LiveHostStatus.idle,
          activeStream: data.stream,
        ));
      case LiveStartConflict(:final streamId):
        emit(state.copyWith(
          status: LiveHostStatus.idle,
          conflictStreamId: streamId,
        ));
      case LiveStartForbidden():
      case LiveStartUnauthorized():
      case LiveStartFailed():
        emit(state.copyWith(status: LiveHostStatus.idle));
    }
    return result;
  }

  /// Возврат в уже идущий эфир после 409 или падения приложения.
  ///
  /// Единственная точка входа для обоих действий диалога — «Завершить и начать
  /// заново» и «Открыть как зритель». Когда бэк научится выдавать
  /// publisher-токен для своего эфира (`POST /live/:id/token` role-aware либо
  /// отдельная ручка), менять придётся только здесь.
  Future<LiveStartResult> restartStream({
    required int streamId,
    required String title,
    String? coverUrl,
  }) async {
    emit(state.copyWith(status: LiveHostStatus.stopping));
    await _repo.stopStream(streamId);
    if (isClosed) return const LiveStartFailed();
    // Ровно одна повторная попытка, без цикла: если и она вернёт 409, значит
    // на сервере что-то другое, и крутить это до бесконечности нельзя.
    return start(title: title, coverUrl: coverUrl);
  }

  /// `POST /live/:id/stop`.
  Future<bool> stop(int streamId) async {
    emit(state.copyWith(status: LiveHostStatus.stopping));
    final result = await _repo.stopStream(streamId);
    if (isClosed) return result is LiveStopOk;
    emit(state.copyWith(status: LiveHostStatus.idle, clearActive: true));
    return result is LiveStopOk;
  }

  /// Сброс при выходе из аккаунта: чужой активный эфир не должен переезжать
  /// к следующему пользователю.
  void reset() => emit(const LiveHostState());
}
