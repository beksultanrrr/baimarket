import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'models/live_stream_info.dart';

/// Временный dev-конфиг для LiveKit Cloud.
///
/// TEMP: пока бэкенд не отдаёт LiveKit-поля в событии `streamStarted`, источник
/// видео (url + room + token) подставляем отсюда. Когда бэк начнёт класть
/// `livekitUrl` / `roomName` / `token` в `streamStarted`, этот файл удаляется,
/// а вызов `resolveLiveKitSource` убирается из UI — клиент больше менять не
/// нужно.
///
/// Поддерживаются два dev-режима получения токена:
///   1. Подпись токена на клиенте из API key + secret (см. ниже) — даёт
///      УНИКАЛЬНЫЙ identity на каждый запуск, поэтому несколько устройств могут
///      смотреть один эфир одновременно. Предпочтительный путь.
///   2. Статический токен `kLiveKitDevToken`, сгенерированный в дашборде
///      (Settings → API keys → Generate Token) — один identity, для проверки
///      на одном устройстве.

/// wss-URL проекта LiveKit Cloud. Берётся из дашборда (вкладка Settings → URL).
const String kLiveKitUrl = 'wss://bai-market-streaming-pn3bqpp0.livekit.cloud';

/// Имя тестовой комнаты.
const String kLiveKitDevRoom = 'test';

/// API key проекта (Settings → API keys). Публичный, не секрет.
const String kLiveKitApiKey = 'APImhJMBejxN3fQ';

/// API secret (показывается один раз при создании ключа в дашборде).
///
/// TEMP / НЕ КОММИТИТЬ. Если задан вместе с [kLiveKitApiKey] — токен
/// подписывается на клиенте с уникальным identity (режим 1). Если пуст —
/// используется статический [kLiveKitDevToken] (режим 2).
const String kLiveKitApiSecret = 'JDEkDBpf7ggvPhXaYr3AsxFKUIdFNBaGZcW4MZlsxcG';

/// Статический viewer-токен из дашборда (фоллбэк, режим 2). Пустой → не
/// используется.
const String kLiveKitDevToken =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJBUEk3MkZldWl0SjlraEwiLCJzdWIiOiJ2aWV3ZXIxIiwiZXhwIjoxNzgyMjMzMDI3LCJuYmYiOjE3ODE2MjgyMjcsImlhdCI6MTc4MTYyODIyNywiaWRlbnRpdHkiOiJ2aWV3ZXIxIiwidmlkZW8iOnsicm9vbUpvaW4iOnRydWUsInJvb20iOiJ0ZXN0IiwiY2FuUHVibGlzaCI6dHJ1ZSwiY2FuU3Vic2NyaWJlIjp0cnVlLCJjYW5QdWJsaXNoRGF0YSI6dHJ1ZX19.2r-qlx-v-ektYoyw4sYnvGUfvvHgiNHNo2jjG0dYmqk';

/// Подпись токена на клиенте включена.
bool get _mintEnabled =>
    kLiveKitApiKey.isNotEmpty && kLiveKitApiSecret.isNotEmpty;

/// Уникальный identity на запуск приложения (чтобы несколько устройств не
/// конфликтовали по одному identity). Вычисляется один раз.
final String _devIdentity = 'viewer-${Random().nextInt(1 << 32)}';

/// Кэш подписанного токена — чтобы при ребилдах не плодить новые identity
/// и не передёргивать соединение.
String? _cachedMintedToken;

String _base64UrlNoPad(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

/// Подписывает viewer-only JWT (HS256) для LiveKit. DEV-ONLY: в проде токен
/// обязан подписываться на сервере (секрет нельзя держать в приложении).
String _mintDevToken() {
  final cached = _cachedMintedToken;
  if (cached != null) return cached;

  final now = DateTime.now();
  final nowSec = now.millisecondsSinceEpoch ~/ 1000;
  final expSec = now.add(const Duration(hours: 6)).millisecondsSinceEpoch ~/ 1000;

  final header = {'alg': 'HS256', 'typ': 'JWT'};
  final payload = {
    'iss': kLiveKitApiKey,
    'sub': _devIdentity,
    'identity': _devIdentity,
    'nbf': nowSec,
    'iat': nowSec,
    'exp': expSec,
    'video': {
      'room': kLiveKitDevRoom,
      'roomJoin': true,
      'canSubscribe': true,
      'canPublish': false, // строго зритель
      'canPublishData': false,
    },
  };

  final encodedHeader = _base64UrlNoPad(utf8.encode(jsonEncode(header)));
  final encodedPayload = _base64UrlNoPad(utf8.encode(jsonEncode(payload)));
  final signingInput = '$encodedHeader.$encodedPayload';
  final signature = Hmac(sha256, utf8.encode(kLiveKitApiSecret))
      .convert(utf8.encode(signingInput));
  final token = '$signingInput.${_base64UrlNoPad(signature.bytes)}';

  _cachedMintedToken = token;
  return token;
}

/// Токен для dev-режима: подписанный на клиенте (уникальный identity) либо
/// статический из дашборда. Пустой → LiveKit выключен.
String _devToken() {
  if (_mintEnabled) return _mintDevToken();
  return kLiveKitDevToken;
}

/// Включён ли dev-режим LiveKit (есть url и хоть какой-то способ получить токен).
bool get kLiveKitDevEnabled =>
    kLiveKitUrl.isNotEmpty && _devToken().isNotEmpty;

/// Синтетические метаданные эфира для dev-проверки, когда бэкенд ещё не шлёт
/// `streamStarted`. Позволяет открыть активный экран эфира без сокет-события.
LiveStreamInfo devLiveStreamInfo() => LiveStreamInfo(
      videoId: '',
      channelTitle: 'LiveKit Test',
      thumbnailUrl: null,
      livekitUrl: kLiveKitUrl,
      roomName: kLiveKitDevRoom,
      token: _devToken(),
    );

/// Возвращает источник видео для эфира.
///
/// Если бэк уже прислал валидные LiveKit-поля (`info.isLiveKit`) — отдаём как
/// есть. Иначе, если включён dev-режим, подставляем dev-источник. В остальных
/// случаях возвращаем `info` без изменений → сработает YouTube-фоллбэк.
LiveStreamInfo resolveLiveKitSource(LiveStreamInfo info) {
  if (info.isLiveKit) return info;
  if (!kLiveKitDevEnabled) return info;
  return info.copyWith(
    livekitUrl: kLiveKitUrl,
    roomName: kLiveKitDevRoom,
    token: _devToken(),
  );
}
