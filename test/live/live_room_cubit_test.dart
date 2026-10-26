import 'package:bai_market/features/live/data/datasources/live_socket_service.dart';
import 'package:bai_market/features/live/data/models/live_chat_message_model.dart';
import 'package:bai_market/features/live/data/models/live_product_card_model.dart';
import 'package:bai_market/features/live/domain/repositories/live_repository.dart';
import 'package:bai_market/features/live/presentation/cubit/live_room_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_live_repository.dart';
import 'fake_live_socket_service.dart';

LiveChatMessageModel msg(int id) =>
    LiveChatMessageModel(id: id, message: 'm$id', fullName: 'Аноним');

void main() {
  late FakeLiveSocketService socket;
  late FakeLiveRepository repo;
  late LiveRoomCubit cubit;

  Future<void> build({LiveRole role = LiveRole.viewer}) async {
    socket = FakeLiveSocketService();
    repo = FakeLiveRepository();
    cubit = LiveRoomCubit(
      streamId: 1,
      role: role,
      repository: repo,
      socket: socket,
    );
    await cubit.start();
  }

  tearDown(() => cubit.close());

  test('start берёт токен зрителя и переходит в фазу live', () async {
    await build();
    expect(repo.tokenCalls, 1);
    expect(cubit.state.phase, LiveRoomPhase.live);
    expect(cubit.state.connection?.token, 'tok');
  });

  test('snapshot ЗАМЕНЯЕТ состояние, а не дописывает его', () async {
    await build();
    socket.chatCtrl.add(msg(1));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.chat.length, 1);

    // Именно замена чинит всё, что клиент пропустил, пока был офлайн.
    socket.snapshotCtrl.add(
      LiveSnapshot(chat: [msg(9)], pinnedProduct: null, viewerCount: 5),
    );
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.chat.length, 1);
    expect(cubit.state.chat.single.id, 9);
    expect(cubit.state.viewerCount, 5);
  });

  test('чат обрезается до maxChatBuffer', () async {
    await build();
    for (var i = 0; i < LiveRoomCubit.maxChatBuffer + 20; i++) {
      socket.chatCtrl.add(msg(i));
      await Future<void>.delayed(Duration.zero);
    }
    expect(cubit.state.chat.length, LiveRoomCubit.maxChatBuffer);
    // Остаётся хвост, а не начало: свежие сообщения важнее.
    expect(cubit.state.chat.last.id, LiveRoomCubit.maxChatBuffer + 19);
  });

  test('product:shown ставит пин, product:hidden снимает', () async {
    await build();
    socket.shownCtrl.add(const LiveProductCardModel(id: 42, name: 'Крем'));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.pinnedProduct?.id, 42);

    socket.hiddenCtrl.add(null);
    await Future<void>.delayed(Duration.zero);
    // Без явного clearPinnedProduct тут остался бы старый товар.
    expect(cubit.state.pinnedProduct, isNull);
  });

  test('stream:ended переводит в ended и снимает пин', () async {
    await build();
    socket.shownCtrl.add(const LiveProductCardModel(id: 42));
    await Future<void>.delayed(Duration.zero);

    socket.endedCtrl.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.phase, LiveRoomPhase.ended);
    expect(cubit.state.pinnedProduct, isNull);
  });

  test('возврат из фона переотправляет joinStream', () async {
    await build();
    await cubit.onResumed();
    // Без повторного joinStream после реконнекта события просто перестают
    // приходить — это и есть самый частый способ «сломать чат».
    expect(socket.rejoinCalls, 1);
  });

  test('404 на токен — это «эфир завершён», а не ошибка', () async {
    socket = FakeLiveSocketService();
    repo = FakeLiveRepository(tokenResult: const LiveViewerTokenNotLive());
    cubit = LiveRoomCubit(
      streamId: 1,
      repository: repo,
      socket: socket,
    );
    await cubit.start();
    expect(cubit.state.phase, LiveRoomPhase.ended);
  });

  test('зритель не может показывать товар', () async {
    await build();
    cubit.showProduct(5);
    cubit.hideProduct();
    expect(socket.shownProducts, isEmpty);
    expect(socket.hideCalls, 0);
  });

  test('ведущий показывает и убирает товар', () async {
    await build(role: LiveRole.host);
    cubit.showProduct(5);
    cubit.hideProduct();
    expect(socket.shownProducts, [5]);
    expect(socket.hideCalls, 1);
  });
}
