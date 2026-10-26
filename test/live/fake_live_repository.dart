import 'package:bai_market/features/live/data/models/live_stream_model.dart';
import 'package:bai_market/features/live/data/models/live_token_response.dart';
import 'package:bai_market/features/live/domain/repositories/live_repository.dart';

LiveStreamModel buildStream({
  int id = 1,
  int sellerId = 7,
  String status = 'LIVE',
}) =>
    LiveStreamModel(
      id: id,
      sellerId: sellerId,
      title: 'Тестовый эфир',
      status: status,
    );

/// Репозиторий с заранее заданными ответами.
class FakeLiveRepository implements LiveRepository {
  FakeLiveRepository({
    this.tokenResult = const LiveViewerTokenOk(
      LiveViewerTokenResponse(token: 'tok', url: 'wss://example'),
    ),
    LiveStreamResult? streamResult,
  }) : streamResult = streamResult ?? LiveStreamLoaded(buildStream());

  LiveViewerTokenResult tokenResult;
  LiveStreamResult streamResult;
  int tokenCalls = 0;

  @override
  Future<LiveViewerTokenResult> getViewerToken(int id) async {
    tokenCalls++;
    return tokenResult;
  }

  @override
  Future<LiveStreamResult> getStream(int id) async => streamResult;

  @override
  Future<LiveListResult> getLiveStreams() async => const LiveListLoaded([]);

  @override
  Future<LiveListResult> getMyStreams() async => const LiveListLoaded([]);

  @override
  Future<LiveStartResult> startStream({
    required String title,
    String? coverUrl,
  }) async =>
      const LiveStartFailed();

  @override
  Future<LiveStopResult> stopStream(int id) async => const LiveStopFailed();

  @override
  Future<LiveChatHistoryResult> getChatHistory(int id) async =>
      const LiveChatHistoryLoaded([]);
}
