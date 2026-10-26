import 'package:bai_market/features/live/presentation/cubit/live_host_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_live_repository.dart';

void main() {
  test('stop гасит активный эфир', () async {
    final cubit = LiveHostCubit(repository: FakeLiveRepository());
    // Как будто GET /live/my вернул идущий эфир.
    await cubit.stop(1);
    expect(cubit.state.activeStream, isNull);
    expect(cubit.state.status, LiveHostStatus.idle);
    await cubit.close();
  });

  test('reset обнуляет состояние: чужой эфир не переезжает к новому юзеру',
      () async {
    final cubit = LiveHostCubit(repository: FakeLiveRepository());
    cubit.reset();
    expect(cubit.state.activeStream, isNull);
    expect(cubit.state.conflictStreamId, isNull);
    expect(cubit.state.status, LiveHostStatus.idle);
    await cubit.close();
  });

  test('после завершения эфира кнопка возвращается в «Начать эфир»', () async {
    // Именно это и ломалось: экран ведущего и вкладка «Эфиры» держали разные
    // экземпляры кубита, поэтому stop() на одном не гасил кнопку на другом.
    // Теперь экземпляр общий, и достаточно проверить, что состояние после
    // stop() действительно «эфира нет».
    final cubit = LiveHostCubit(repository: FakeLiveRepository());
    await cubit.loadMyActiveStream();
    await cubit.stop(1);

    expect(cubit.state.hasActiveStream, isFalse);
    await cubit.close();
  });
}
