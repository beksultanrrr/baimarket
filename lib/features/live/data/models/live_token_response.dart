import 'package:json_annotation/json_annotation.dart';

import 'live_stream_model.dart';

part 'live_token_response.g.dart';

/// Пара «куда подключаться» + «с каким токеном» для LiveKit.
///
/// Отдельный тип, потому что через него проходят оба сценария, а вот права у
/// токенов разные: у ведущего — с публикацией, у зрителя — только подписка.
class LiveConnection {
  const LiveConnection({required this.url, required this.token});

  /// `wss://<project>.livekit.cloud`
  final String url;
  final String token;

  bool get isUsable => url.isNotEmpty && token.isNotEmpty;
}

/// Ответ `POST /live/start` — 201.
///
/// `token` здесь **publisher**-овский: только он даёт право включить камеру и
/// микрофон. Второй раз его получить нельзя — `POST /live/:id/token` отдаёт
/// зрительский. Поэтому он и не смешивается с [LiveViewerTokenResponse]:
/// перепутать их местами не даст сама типизация.
@JsonSerializable(explicitToJson: true)
class LiveStartResponse {
  final LiveStreamModel stream;
  final String token;
  final String url;

  const LiveStartResponse({
    required this.stream,
    required this.token,
    required this.url,
  });

  LiveConnection get connection => LiveConnection(url: url, token: token);

  factory LiveStartResponse.fromJson(Map<String, dynamic> json) =>
      _$LiveStartResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LiveStartResponseToJson(this);
}

/// Ответ `POST /live/:id/token` — 201.
///
/// `token` **зрительский**: подписка есть, публикации нет.
@JsonSerializable(explicitToJson: true)
class LiveViewerTokenResponse {
  final String token;
  final String url;
  final LiveStreamModel? stream;

  const LiveViewerTokenResponse({
    required this.token,
    required this.url,
    this.stream,
  });

  LiveConnection get connection => LiveConnection(url: url, token: token);

  factory LiveViewerTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$LiveViewerTokenResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LiveViewerTokenResponseToJson(this);
}
