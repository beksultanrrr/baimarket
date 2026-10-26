part of 'live_host_cubit.dart';

enum LiveHostStatus { idle, starting, stopping }

class LiveHostState extends Equatable {
  const LiveHostState({
    this.status = LiveHostStatus.idle,
    this.activeStream,
    this.conflictStreamId,
  });

  final LiveHostStatus status;

  /// Мой идущий эфир, если он есть. Питает второе состояние кнопки на вкладке
  /// «Эфиры» — «Вернуться в свой эфир».
  final LiveStreamModel? activeStream;

  /// Пришёл 409: эфир уже идёт под этим id. Второй создавать нельзя.
  final int? conflictStreamId;

  bool get isBusy => status != LiveHostStatus.idle;
  bool get hasActiveStream => activeStream != null;

  LiveHostState copyWith({
    LiveHostStatus? status,
    LiveStreamModel? activeStream,
    int? conflictStreamId,
    bool clearActive = false,
    bool clearOutcome = false,
  }) {
    return LiveHostState(
      status: status ?? this.status,
      activeStream: clearActive ? null : (activeStream ?? this.activeStream),
      conflictStreamId:
          clearOutcome ? null : (conflictStreamId ?? this.conflictStreamId),
    );
  }

  @override
  List<Object?> get props => [status, activeStream?.id, conflictStreamId];
}
