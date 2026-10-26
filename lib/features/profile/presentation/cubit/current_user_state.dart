part of 'current_user_cubit.dart';

enum CurrentUserStatus {
  initial,
  loading,

  /// Роль получена.
  loaded,

  /// Не авторизован — штатное состояние, а не ошибка.
  guest,

  /// Запрос не удался. Предыдущая роль (если была) сохраняется.
  error,
}

class CurrentUserState extends Equatable {
  const CurrentUserState({
    this.status = CurrentUserStatus.initial,
    this.user,
  });

  final CurrentUserStatus status;
  final CurrentUserModel? user;

  /// Показывать ли вход в эфир.
  ///
  /// Пока роль не известна (initial/loading/guest/ошибка) — не показываем.
  /// Лучше не показать кнопку продавцу на секунду дольше, чем показать её
  /// покупателю и упереться в 403 уже после запроса камеры.
  bool get canOpenStreaming => user?.canOpenStreaming ?? false;

  bool get isSeller => user?.isSeller ?? false;
  bool get isAdmin => user?.isAdmin ?? false;

  /// `id` текущего пользователя — например, чтобы подсветить свои сообщения
  /// в чате эфира.
  int? get userId => user?.id;

  CurrentUserState copyWith({
    CurrentUserStatus? status,
    CurrentUserModel? user,
  }) {
    return CurrentUserState(
      status: status ?? this.status,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [status, user?.id, user?.role, user?.isActive];
}
