import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/profile_services.dart';
import '../../data/models/current_user_model.dart';
import '../../domain/repositories/profile_repository.dart';

part 'current_user_state.dart';

/// Кто сейчас в приложении и какая у него роль (`GET /users/me/profile`).
///
/// Отдельно от [ProfileCubit]: тот держит экран профиля со счётчиками
/// избранного, призов и билетов и перезагружается вместе с ним. Роль же нужна
/// в других местах (вкладка «Эфиры»), живёт всю сессию и меняется только при
/// входе/выходе.
///
/// Регистрируется глобально в `main.dart`.
class CurrentUserCubit extends Cubit<CurrentUserState> {
  CurrentUserCubit({ProfileRepository? profileRepository})
      : _repo = profileRepository ?? ProfileServices(),
        super(const CurrentUserState());

  final ProfileRepository _repo;
  bool _loadedOnce = false;

  /// Загрузить один раз за сессию. Безопасно звать из нескольких мест.
  Future<void> ensureLoaded() async {
    if (_loadedOnce) return;
    _loadedOnce = true;
    await load();
  }

  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(status: CurrentUserStatus.loading));

    final result = await _repo.getCurrentUser();
    if (isClosed) return;
    switch (result) {
      case CurrentUserLoaded(:final user):
        emit(CurrentUserState(status: CurrentUserStatus.loaded, user: user));
      case CurrentUserUnauthorized():
        // Гость — это не ошибка. Роли просто нет, и всё ролевое скрыто.
        emit(const CurrentUserState(status: CurrentUserStatus.guest));
      case CurrentUserFailed():
        // Сеть подвела: прошлую роль не стираем, иначе у продавца на плохой
        // связи кнопка входа в эфир мигала бы.
        emit(state.copyWith(status: CurrentUserStatus.error));
    }
  }

  /// После логина роль надо перечитать заново.
  Future<void> reload() {
    _loadedOnce = true;
    return load();
  }

  void reset() {
    _loadedOnce = false;
    emit(const CurrentUserState());
  }
}
