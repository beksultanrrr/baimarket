import 'package:bai_market/features/profile/data/models/current_user_model.dart';
import 'package:bai_market/features/profile/data/models/profile_model.dart';
import 'package:bai_market/features/profile/domain/repositories/profile_repository.dart';
import 'package:bai_market/features/profile/presentation/cubit/current_user_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this.result);

  CurrentUserResult result;
  int calls = 0;

  @override
  Future<CurrentUserResult> getCurrentUser() async {
    calls++;
    return result;
  }

  @override
  Future<ProfileModel?> getProfileData() async => null;
}

CurrentUserModel user({String role = 'USER', bool isActive = true}) =>
    CurrentUserModel(id: 1, role: role, isActive: isActive);

void main() {
  group('видимость входа в эфир', () {
    test('покупатель его не видит', () async {
      final cubit = CurrentUserCubit(
        profileRepository: _FakeProfileRepository(
          CurrentUserLoaded(user(role: 'USER')),
        ),
      );
      await cubit.load();
      expect(cubit.state.canOpenStreaming, isFalse);
      await cubit.close();
    });

    test('продавец видит', () async {
      final cubit = CurrentUserCubit(
        profileRepository: _FakeProfileRepository(
          CurrentUserLoaded(user(role: 'SELLER')),
        ),
      );
      await cubit.load();
      expect(cubit.state.canOpenStreaming, isTrue);
      expect(cubit.state.isSeller, isTrue);
      await cubit.close();
    });

    test('админ НЕ видит: эфир ведёт продавец, админ только выдаёт доступ',
        () async {
      final cubit = CurrentUserCubit(
        profileRepository: _FakeProfileRepository(
          CurrentUserLoaded(user(role: 'ADMIN')),
        ),
      );
      await cubit.load();
      expect(cubit.state.canOpenStreaming, isFalse);
      expect(cubit.state.isAdmin, isTrue);
      await cubit.close();
    });

    test('отключённый продавец не видит: сервер всё равно ответит 403',
        () async {
      final cubit = CurrentUserCubit(
        profileRepository: _FakeProfileRepository(
          CurrentUserLoaded(user(role: 'SELLER', isActive: false)),
        ),
      );
      await cubit.load();
      expect(cubit.state.canOpenStreaming, isFalse);
      await cubit.close();
    });

    test('гость не видит', () async {
      final cubit = CurrentUserCubit(
        profileRepository:
            _FakeProfileRepository(const CurrentUserUnauthorized()),
      );
      await cubit.load();
      expect(cubit.state.status, CurrentUserStatus.guest);
      expect(cubit.state.canOpenStreaming, isFalse);
      await cubit.close();
    });

    test('неизвестная роль трактуется как покупатель, а не роняет разбор',
        () async {
      final cubit = CurrentUserCubit(
        profileRepository: _FakeProfileRepository(
          CurrentUserLoaded(user(role: 'MODERATOR')),
        ),
      );
      await cubit.load();
      expect(cubit.state.canOpenStreaming, isFalse);
      await cubit.close();
    });
  });

  test('ошибка сети не стирает уже известную роль', () async {
    final repo = _FakeProfileRepository(CurrentUserLoaded(user(role: 'SELLER')));
    final cubit = CurrentUserCubit(profileRepository: repo);
    await cubit.load();
    expect(cubit.state.canOpenStreaming, isTrue);

    // Иначе у продавца на плохой связи кнопка входа в эфир мигала бы.
    repo.result = const CurrentUserFailed();
    await cubit.load();
    expect(cubit.state.status, CurrentUserStatus.error);
    expect(cubit.state.canOpenStreaming, isTrue);
    await cubit.close();
  });

  test('ensureLoaded ходит на сервер один раз, reload — заново', () async {
    final repo = _FakeProfileRepository(CurrentUserLoaded(user()));
    final cubit = CurrentUserCubit(profileRepository: repo);
    await cubit.ensureLoaded();
    await cubit.ensureLoaded();
    expect(repo.calls, 1);

    // После логина роль обязана перечитаться: пользователь уже другой.
    await cubit.reload();
    expect(repo.calls, 2);
    await cubit.close();
  });

  test('reset обнуляет роль и разрешает повторную загрузку', () async {
    final repo = _FakeProfileRepository(CurrentUserLoaded(user(role: 'SELLER')));
    final cubit = CurrentUserCubit(profileRepository: repo);
    await cubit.ensureLoaded();
    expect(cubit.state.canOpenStreaming, isTrue);

    cubit.reset();
    expect(cubit.state.canOpenStreaming, isFalse);
    expect(cubit.state.status, CurrentUserStatus.initial);

    await cubit.ensureLoaded();
    expect(repo.calls, 2);
    await cubit.close();
  });

  test('модель разбирает ответ GET /users/me/profile', () {
    final parsed = CurrentUserModel.fromJson(const {
      'id': 1,
      'phoneNumber': '77001234567',
      'role': 'SELLER',
      'isActive': true,
      'createdAt': '2026-07-29T10:00:00.000Z',
      'updatedAt': '2026-07-29T10:00:00.000Z',
      'profile': {
        'userId': 1,
        'firstName': 'Алия',
        'lastName': 'Нурланова',
        'avatarUrl': 'abc123.jpg',
      },
    });

    expect(parsed.id, 1);
    expect(parsed.isSeller, isTrue);
    expect(parsed.canOpenStreaming, isTrue);
    expect(parsed.profile?.displayName, 'Алия Нурланова');
    expect(parsed.profile?.avatarUrl, 'abc123.jpg');
  });
}
