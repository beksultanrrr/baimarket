part of 'live_list_cubit.dart';

enum LiveListStatus { initial, loading, loaded, error }

class LiveListState extends Equatable {
  const LiveListState({
    this.status = LiveListStatus.initial,
    this.streams = const [],
  });

  final LiveListStatus status;
  final List<LiveStreamModel> streams;

  /// «Загрузились и никого нет» — отдельное состояние от «ещё грузим»: у них
  /// разные экраны.
  bool get isEmpty => status == LiveListStatus.loaded && streams.isEmpty;

  LiveListState copyWith({
    LiveListStatus? status,
    List<LiveStreamModel>? streams,
  }) {
    return LiveListState(
      status: status ?? this.status,
      streams: streams ?? this.streams,
    );
  }

  @override
  List<Object?> get props => [
        status,
        streams.length,
        // Иначе смена набора эфиров при том же их количестве не долетит до UI.
        streams.map((s) => '${s.id}:${s.viewerCount}:${s.pinnedModel?.id}')
            .join(','),
      ];
}
