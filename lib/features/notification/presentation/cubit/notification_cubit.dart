import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/notification_services.dart';
import '../../data/models/notification_model.dart';
import '../../domain/repositories/notification_repository.dart';

part 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _notificationRepository;

  NotificationCubit({NotificationRepository? notificationRepository})
    : _notificationRepository =
          notificationRepository ?? NotificationServices(),
      super(NotificationInitial());

  void reset() => emit(NotificationInitial());

  /// Непрочитанные — для бейджа на колокольчике.
  int get unreadCount {
    final s = state;
    if (s is! NotificationGot) return 0;
    return s.notifications.where((n) => !n.read).length;
  }

  Future<void> getNotifications() async {
    emit(NotificationGetting());
    try {
      final notifications = await _notificationRepository.getNotification();
      // Пустой список — это не ошибка. Раньше пользователь без уведомлений
      // видел экран ошибки, неотличимый от сбоя сети.
      emit(NotificationGot(notifications: notifications));
    } catch (e) {
      emit(NotificationGetError());
    }
  }

  /// Тихое обновление — без перехода в состояние загрузки, чтобы список не
  /// мигал при приходе пуша.
  Future<void> refresh() async {
    try {
      final notifications = await _notificationRepository.getNotification();
      emit(NotificationGot(notifications: notifications));
    } catch (_) {
      // Держим то, что уже показано.
    }
  }
}
