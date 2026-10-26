import 'live_stream_model.dart';
import 'live_token_response.dart';

/// Аргументы перехода на экран ведущего.
///
/// Обычный payload навигации, не JsonSerializable — как `PaymentArgs`.
/// Здесь лежит **publisher**-токен из ответа `POST /live/start`: второй раз его
/// получить неоткуда, `POST /live/:id/token` отдаёт зрительский. Поэтому его
/// нельзя терять между экранами и нельзя восстанавливать запросом.
class LiveHostArgs {
  const LiveHostArgs({
    required this.stream,
    required this.connection,
  });

  factory LiveHostArgs.fromStartResponse(LiveStartResponse response) =>
      LiveHostArgs(
        stream: response.stream,
        connection: response.connection,
      );

  final LiveStreamModel stream;
  final LiveConnection connection;
}
