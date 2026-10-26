import 'dart:async';

import 'package:bai_market/features/live/data/datasources/live_socket_service.dart';
import 'package:bai_market/features/live/data/models/live_chat_message_model.dart';
import 'package:bai_market/features/live/data/models/live_product_card_model.dart';

/// Управляемый вручную сокет для тестов.
///
/// Наследуемся от настоящего сервиса и подменяем потоки: так тест проверяет
/// именно ту машину состояний, которую использует продакшен-код, и не зависит
/// от живого socket.io.
class FakeLiveSocketService extends LiveSocketService {
  FakeLiveSocketService({super.streamId = 1});

  final connectionCtrl = StreamController<bool>.broadcast();
  final snapshotCtrl = StreamController<LiveSnapshot>.broadcast();
  final chatCtrl = StreamController<LiveChatMessageModel>.broadcast();
  final shownCtrl = StreamController<LiveProductCardModel>.broadcast();
  final hiddenCtrl = StreamController<void>.broadcast();
  final viewersCtrl = StreamController<int>.broadcast();
  final endedCtrl = StreamController<void>.broadcast();
  final errorCtrl = StreamController<String>.broadcast();

  int connectCalls = 0;
  int rejoinCalls = 0;
  final List<int> shownProducts = [];
  int hideCalls = 0;

  @override
  Stream<bool> get connection => connectionCtrl.stream;
  @override
  Stream<LiveSnapshot> get snapshot => snapshotCtrl.stream;
  @override
  Stream<LiveChatMessageModel> get chatMessage => chatCtrl.stream;
  @override
  Stream<LiveProductCardModel> get productShown => shownCtrl.stream;
  @override
  Stream<void> get productHidden => hiddenCtrl.stream;
  @override
  Stream<int> get viewers => viewersCtrl.stream;
  @override
  Stream<void> get streamEnded => endedCtrl.stream;
  @override
  Stream<String> get socketError => errorCtrl.stream;

  @override
  bool get isConnected => true;

  @override
  Future<bool> connect() async {
    connectCalls++;
    connectionCtrl.add(true);
    return true;
  }

  @override
  void rejoin() => rejoinCalls++;

  @override
  void showProduct(int modelId) => shownProducts.add(modelId);

  @override
  void hideProduct() => hideCalls++;

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> dispose() async {
    await connectionCtrl.close();
    await snapshotCtrl.close();
    await chatCtrl.close();
    await shownCtrl.close();
    await hiddenCtrl.close();
    await viewersCtrl.close();
    await endedCtrl.close();
    await errorCtrl.close();
  }
}
