import 'package:dio/dio.dart';

import '../../../../core/network/app_dio.dart';
import '../../../../core/services/live_logger.dart';
import '../../../../core/urls.dart';
import '../../domain/repositories/live_repository.dart';
import '../models/live_chat_message_model.dart';
import '../models/live_stream_model.dart';
import '../models/live_token_response.dart';

/// REST-часть эфиров. Управление и токены; видео идёт через LiveKit, а чат и
/// закреплённый товар — через сокет `/live`.
///
/// Админские ручки (`GET /live/admin`, `POST /live/:id/admin-stop`,
/// `DELETE /live/chat/:messageId`) и вебхук LiveKit сюда намеренно не входят —
/// это веб-модерация.
class LiveServices implements LiveRepository {
  /// Лента доступна гостю: вкладка «Эфиры» открыта без авторизации, а `appDio`
  /// без токена отклоняет запрос локально синтетическим 401 и до сети не
  /// доходит — гость увидел бы вечную ошибку.
  final Dio _publicDio = optionalAuthDio;

  /// Всё остальное требует токена по контракту.
  final Dio _authDio = appDio;

  @override
  Future<LiveListResult> getLiveStreams() =>
      _loadList(_publicDio, '${mainUrl}live', 'getLiveStreams');

  @override
  Future<LiveListResult> getMyStreams() =>
      _loadList(_authDio, '${mainUrl}live/my', 'getMyStreams');

  Future<LiveListResult> _loadList(Dio dio, String url, String tag) async {
    try {
      final response = await dio.get(url);
      if (response.statusCode != 200 || response.data is! List) {
        liveLog.warn(
          '$tag unexpected response',
          'status=${response.statusCode}, data=${response.data.runtimeType}',
        );
        return const LiveListFailed();
      }
      return LiveListLoaded(_parseStreams(response.data as List, tag));
    } on DioException catch (e) {
      liveLog.error('$tag dio error', e.toString(), e);
      return const LiveListFailed();
    } catch (e, st) {
      liveLog.error('$tag exception', e.toString(), e, st);
      return const LiveListFailed();
    }
  }

  /// Каждый элемент парсится сам по себе: одна кривая запись не должна
  /// обнулять всю ленту.
  List<LiveStreamModel> _parseStreams(List raw, String tag) {
    final result = <LiveStreamModel>[];
    for (final item in raw) {
      if (item is! Map) continue;
      try {
        result.add(LiveStreamModel.fromJson(Map<String, dynamic>.from(item)));
      } catch (e) {
        liveLog.warn('$tag skipped malformed stream', e.toString());
      }
    }
    return result;
  }

  @override
  Future<LiveStreamResult> getStream(int id) async {
    try {
      final response = await _authDio.get('${mainUrl}live/$id');
      if (response.statusCode != 200 || response.data is! Map) {
        liveLog.warn(
          'getStream unexpected response',
          'status=${response.statusCode}, data=${response.data.runtimeType}',
        );
        return const LiveStreamFailed();
      }
      return LiveStreamLoaded(
        LiveStreamModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        liveLog.warn('getStream 404', 'stream=$id');
        return const LiveStreamNotFound();
      }
      liveLog.error('getStream dio error', e.toString(), e);
      return const LiveStreamFailed();
    } catch (e, st) {
      liveLog.error('getStream exception', e.toString(), e, st);
      return const LiveStreamFailed();
    }
  }

  @override
  Future<LiveStartResult> startStream({
    required String title,
    String? coverUrl,
  }) async {
    try {
      final response = await _authDio.post(
        '${mainUrl}live/start',
        data: {
          'title': title,
          if (coverUrl != null && coverUrl.isNotEmpty) 'coverUrl': coverUrl,
        },
      );
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300 || response.data is! Map) {
        liveLog.warn(
          'startStream unexpected response',
          'status=$status, data=${response.data.runtimeType}',
        );
        return const LiveStartFailed();
      }
      return LiveStartOk(
        LiveStartResponse.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        ),
      );
    } on DioException catch (e) {
      switch (e.response?.statusCode) {
        case 403:
          liveLog.warn('startStream 403 — нет доступа к эфирам');
          return const LiveStartForbidden();
        case 409:
          final streamId = _readStreamId(e.response?.data);
          liveLog.warn('startStream 409 — эфир уже идёт', 'stream=$streamId');
          return LiveStartConflict(
            streamId: streamId,
            message: _readMessage(e.response?.data),
          );
        case 401:
          liveLog.warn('startStream 401');
          return const LiveStartUnauthorized();
      }
      liveLog.error('startStream dio error', e.toString(), e);
      return const LiveStartFailed();
    } catch (e, st) {
      liveLog.error('startStream exception', e.toString(), e, st);
      return const LiveStartFailed();
    }
  }

  @override
  Future<LiveStopResult> stopStream(int id) async {
    try {
      final response = await _authDio.post('${mainUrl}live/$id/stop');
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300 || response.data is! Map) {
        liveLog.warn('stopStream unexpected response', 'status=$status');
        return const LiveStopFailed();
      }
      return LiveStopOk(
        LiveStreamModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        ),
      );
    } on DioException catch (e) {
      liveLog.error('stopStream dio error', e.toString(), e);
      return const LiveStopFailed();
    } catch (e, st) {
      liveLog.error('stopStream exception', e.toString(), e, st);
      return const LiveStopFailed();
    }
  }

  @override
  Future<LiveViewerTokenResult> getViewerToken(int id) async {
    try {
      final response = await _authDio.post('${mainUrl}live/$id/token');
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300 || response.data is! Map) {
        liveLog.warn('getViewerToken unexpected response', 'status=$status');
        return const LiveViewerTokenFailed();
      }
      return LiveViewerTokenOk(
        LiveViewerTokenResponse.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        ),
      );
    } on DioException catch (e) {
      switch (e.response?.statusCode) {
        case 404:
          // Не ошибка сети: эфир просто уже не идёт.
          liveLog.warn('getViewerToken 404 — эфир не LIVE', 'stream=$id');
          return const LiveViewerTokenNotLive();
        case 401:
          return const LiveViewerTokenUnauthorized();
      }
      liveLog.error('getViewerToken dio error', e.toString(), e);
      return const LiveViewerTokenFailed();
    } catch (e, st) {
      liveLog.error('getViewerToken exception', e.toString(), e, st);
      return const LiveViewerTokenFailed();
    }
  }

  @override
  Future<LiveChatHistoryResult> getChatHistory(int id) async {
    try {
      final response = await _authDio.get('${mainUrl}live/$id/chat');
      if (response.statusCode != 200 || response.data is! List) {
        liveLog.warn('getChatHistory unexpected response');
        return const LiveChatHistoryFailed();
      }
      final messages = <LiveChatMessageModel>[];
      for (final item in response.data as List) {
        if (item is! Map) continue;
        try {
          messages.add(
            LiveChatMessageModel.fromJson(Map<String, dynamic>.from(item)),
          );
        } catch (e) {
          liveLog.warn('getChatHistory skipped malformed message', e.toString());
        }
      }
      return LiveChatHistoryLoaded(messages);
    } on DioException catch (e) {
      liveLog.error('getChatHistory dio error', e.toString(), e);
      return const LiveChatHistoryFailed();
    } catch (e, st) {
      liveLog.error('getChatHistory exception', e.toString(), e, st);
      return const LiveChatHistoryFailed();
    }
  }

  /// `streamId` из тела 409. Терпим и число, и строку — на это уже наступали
  /// с другими ручками.
  int? _readStreamId(Object? data) {
    if (data is! Map) return null;
    final raw = data['streamId'];
    if (raw is int) return raw;
    return int.tryParse('$raw');
  }

  String? _readMessage(Object? data) {
    if (data is! Map) return null;
    final raw = data['message'];
    if (raw is String && raw.trim().isNotEmpty) return raw;
    return null;
  }
}
