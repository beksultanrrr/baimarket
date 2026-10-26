import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/live_services.dart';
import '../../data/models/live_stream_model.dart';
import '../../domain/repositories/live_repository.dart';

part 'live_list_state.dart';

/// Лента идущих эфиров — `GET /live`.
///
/// Ленивый: первую загрузку делает вкладка «Эфиры», когда её действительно
/// открыли. `StreamsPage` постоянно смонтирована внутри `IndexedStack`, так
/// что грузить из `initState` значило бы дёргать ручку на холодном старте у
/// каждого пользователя, включая тех, кто на эту вкладку никогда не заходит.
class LiveListCubit extends Cubit<LiveListState> {
  LiveListCubit({
    LiveRepository? repository,
    Duration pollInterval = const Duration(seconds: 45),
  })  : _repo = repository ?? LiveServices(),
        // ignore: prefer_initializing_formals — приватное поле с дефолтом
        _pollInterval = pollInterval,
        super(const LiveListState());

  final LiveRepository _repo;
  final Duration _pollInterval;
  Timer? _poller;
  bool _loadedOnce = false;

  /// Первая загрузка. Повторные вызовы игнорируются — вкладку переключают
  /// туда-сюда часто.
  Future<void> ensureLoaded() async {
    if (_loadedOnce) return;
    _loadedOnce = true;
    await load();
  }

  /// [silent] — не показывать спиннер поверх уже загруженной ленты.
  Future<void> load({bool silent = false}) async {
    if (isClosed) return;
    if (!silent) emit(state.copyWith(status: LiveListStatus.loading));

    final result = await _repo.getLiveStreams();
    if (isClosed) return;
    switch (result) {
      case LiveListLoaded(:final streams):
        emit(state.copyWith(status: LiveListStatus.loaded, streams: streams));
      case LiveListFailed():
        // При фоновом обновлении уже показанную ленту не сносим: пользователь
        // смотрит на карточки, а не на ошибку сети.
        if (silent && state.streams.isNotEmpty) return;
        emit(state.copyWith(status: LiveListStatus.error));
    }
  }

  Future<void> refresh() => load(silent: state.streams.isNotEmpty);

  /// Поллинг живёт только пока вкладка открыта и приложение на переднем плане:
  /// прошлый глобальный кубит дёргал сокет каждые 15 секунд всегда и у всех.
  void startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(_pollInterval, (_) => load(silent: true));
  }

  void stopPolling() {
    _poller?.cancel();
    _poller = null;
  }

  @override
  Future<void> close() {
    _poller?.cancel();
    return super.close();
  }
}
