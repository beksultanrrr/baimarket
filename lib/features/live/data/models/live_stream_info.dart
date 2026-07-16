/// Метаданные текущего активного стрима, приходящие в `streamStarted`.
class LiveStreamInfo {
  /// YouTube videoId — путь для старого бэка (фоллбэк).
  final String videoId;
  final String channelTitle;
  final String? thumbnailUrl;

  /// LiveKit-поля. Заполняются, когда бэк отдаёт эфир через LiveKit Cloud.
  /// До этого подставляются из dev-конфига (см. `livekit_config.dart`).
  final String? livekitUrl;
  final String? roomName;
  final String? token;

  const LiveStreamInfo({
    required this.videoId,
    required this.channelTitle,
    required this.thumbnailUrl,
    this.livekitUrl,
    this.roomName,
    this.token,
  });

  /// Эфир идёт через LiveKit, если есть url + токен.
  bool get isLiveKit =>
      (livekitUrl?.isNotEmpty ?? false) && (token?.isNotEmpty ?? false);

  LiveStreamInfo copyWith({
    String? videoId,
    String? channelTitle,
    String? thumbnailUrl,
    String? livekitUrl,
    String? roomName,
    String? token,
  }) {
    return LiveStreamInfo(
      videoId: videoId ?? this.videoId,
      channelTitle: channelTitle ?? this.channelTitle,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      livekitUrl: livekitUrl ?? this.livekitUrl,
      roomName: roomName ?? this.roomName,
      token: token ?? this.token,
    );
  }

  factory LiveStreamInfo.fromJson(Map<String, dynamic> json) {
    return LiveStreamInfo(
      videoId: (json['videoId'] ?? '').toString(),
      channelTitle: (json['channelTitle'] ?? '').toString(),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      livekitUrl: json['livekitUrl'] as String?,
      roomName: json['roomName'] as String?,
      token: json['token'] as String?,
    );
  }
}
