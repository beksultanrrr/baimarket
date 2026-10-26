part of 'notification_cubit.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationGetting extends NotificationState {}

class NotificationGot extends NotificationState {
  final List<NotificationModel> notifications;
  const NotificationGot({required this.notifications});

  /// Без этого `props` наследуется пустым и Cubit схлопывает два подряд идущих
  /// `NotificationGot` — обновление по приходу пуша не доезжало бы до UI.
  @override
  List<Object> get props => [
        notifications.length,
        notifications.where((n) => !n.read).length,
        notifications.isEmpty ? 0 : notifications.first.id,
      ];
}

class NotificationGetError extends NotificationState {}
