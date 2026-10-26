// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_token_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiveStartResponse _$LiveStartResponseFromJson(Map<String, dynamic> json) =>
    LiveStartResponse(
      stream: LiveStreamModel.fromJson(json['stream'] as Map<String, dynamic>),
      token: json['token'] as String,
      url: json['url'] as String,
    );

Map<String, dynamic> _$LiveStartResponseToJson(LiveStartResponse instance) =>
    <String, dynamic>{
      'stream': instance.stream.toJson(),
      'token': instance.token,
      'url': instance.url,
    };

LiveViewerTokenResponse _$LiveViewerTokenResponseFromJson(
  Map<String, dynamic> json,
) => LiveViewerTokenResponse(
  token: json['token'] as String,
  url: json['url'] as String,
  stream: json['stream'] == null
      ? null
      : LiveStreamModel.fromJson(json['stream'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LiveViewerTokenResponseToJson(
  LiveViewerTokenResponse instance,
) => <String, dynamic>{
  'token': instance.token,
  'url': instance.url,
  'stream': instance.stream?.toJson(),
};
