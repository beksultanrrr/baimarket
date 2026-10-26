import '../../data/models/current_user_model.dart';
import '../../data/models/profile_model.dart';

/// Результат `GET /users/me/profile`.
///
/// Гость здесь — не ошибка, а штатное состояние: вкладку «Эфиры» открывают и
/// без авторизации. Разница между «не залогинен» и «не смогли спросить» важна:
/// от неё зависит, показывать ли вход в эфир.
sealed class CurrentUserResult {
  const CurrentUserResult();
}

class CurrentUserLoaded extends CurrentUserResult {
  const CurrentUserLoaded(this.user);
  final CurrentUserModel user;
}

/// Токена нет либо он протух.
class CurrentUserUnauthorized extends CurrentUserResult {
  const CurrentUserUnauthorized();
}

class CurrentUserFailed extends CurrentUserResult {
  const CurrentUserFailed();
}

abstract class ProfileRepository {
  /// `GET /profile/me/summary` — экран профиля со счётчиками.
  Future<ProfileModel?> getProfileData();

  /// `GET /users/me/profile` — личность и роль (`USER` / `SELLER` / `ADMIN`).
  Future<CurrentUserResult> getCurrentUser();
}
