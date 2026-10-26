import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'push/push_background_handler.dart';
import 'push/push_channels.dart';
import 'push/push_events.dart';
import 'push/push_message_router.dart';
import 'push/push_token_sync.dart';
import 'services/app_logger.dart';

/// Пуш-уведомления: инициализация Firebase Messaging и Awesome Notifications.
///
/// Класс стал тонким фасадом — вся содержательная логика вынесена в
/// `core/push/*`. Инициализация разделена на два этапа: [initEarly] выполняется
/// в `main()` и не ходит в сеть, [initAfterUi] — после первого кадра, чтобы не
/// держать сплэш.
class FirebaseMessagingService {
  FirebaseMessagingService._();

  static final _messaging = FirebaseMessaging.instance;

  /// Быстрая часть: каналы, слушатели, фоновый обработчик. Не бросает наружу —
  /// иначе `catch` в `main()` подменит всё приложение экраном ошибки.
  static Future<void> initEarly() async {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Автоинициализация была выключена и в манифесте, и в Info.plist —
      // из-за этого SDK не обновлял токен самостоятельно. Флаг сохраняется в
      // нативных prefs, поэтому покрывает и уже установленные устройства.
      await _messaging.setAutoInitEnabled(true);

      await AwesomeNotifications().initialize(
        null,
        [buildDefaultChannel()],
        debug: false,
      );

      // Разрешение здесь НЕ запрашиваем: раньше системный диалог всплывал на
      // сплэше, до любого объяснения, а результат никто не проверял. Теперь
      // его запрашивает `PushGate` после первого кадра — см.
      // `core/push/push_gate.dart`.
      AwesomeNotifications().setListeners(
        onActionReceivedMethod: onNotificationActionReceived,
        onNotificationCreatedMethod: _onNotificationCreated,
        onNotificationDisplayedMethod: _onNotificationDisplayed,
        onDismissActionReceivedMethod: _onDismissActionReceived,
      );

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpened);
      _messaging.onTokenRefresh.listen(PushTokenSync.onTokenRefresh);
    } catch (e, st) {
      pushLog.error('initEarly failed', e.toString(), e, st);
    }
  }

  /// Сетевая часть: регистрация токена и разбор холодного старта по тапу.
  static Future<void> initAfterUi() async {
    try {
      // force: холодный старт всегда переотправляет токен, не сверяясь ни со
      // сроком свежести, ни с тем, что токен не менялся. Дороже на один POST
      // за запуск, зато расхождение «на сервере лежит не то» лечится первым
      // же открытием приложения, а не через неделю.
      await PushTokenSync.ensureRegistered(
        trigger: PushSyncTrigger.start,
        force: true,
      );
      await _handleInitialMessage();
    } catch (e, st) {
      pushLog.error('initAfterUi failed', e.toString(), e, st);
    }
  }

  /// Совместимость со старым вызовом из `main()`.
  static Future<void> init() => initEarly();

  static Future<void> requestPermissionIfNeeded() async {
    if (Platform.isIOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    }
    final allowed = await AwesomeNotifications().isNotificationAllowed();
    if (!allowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  static Future<bool> isAllowed() =>
      AwesomeNotifications().isNotificationAllowed();

  static Future<void> openSystemSettings() =>
      AwesomeNotifications().showNotificationConfigPage();

  /// Холодный старт требует **двух** проверок, а не одной:
  /// * `getInitialMessage` — тап по уведомлению из системного трея;
  /// * `getInitialNotificationAction` — тап по уведомлению, созданному самим
  ///   приложением. Второй раньше отсутствовал вовсе, поэтому такие тапы были
  ///   мертвы.
  static Future<void> _handleInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await PushMessageRouter.handleTap(initialMessage.data);
      return;
    }
    final action = await AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: true);
    if (action != null) {
      await PushMessageRouter.handleTap(_payloadOf(action));
    }
  }

  /// Нужна ли своя копия пуша, пришедшего, пока приложение открыто.
  ///
  /// На iOS пуш с блоком `notification` уже показала система: FCM-плагин
  /// отдаёт решение о показе делегату awesome_notifications, и тот выводит
  /// баннер. Своя копия удваивала бы каждый такой пуш — от того же защищается
  /// фоновый обработчик. На Android система пуш на переднем плане не
  /// показывает, поэтому там копия нужна всегда, как и data-only пушам на iOS.
  /// Пуш без заголовка и текста не показываем нигде. Чистая — проверяется тестом.
  static bool needsLocalCopy({
    required bool isIOS,
    required bool hasNotificationBlock,
    String? title,
    String? body,
  }) {
    if (title == null && body == null) return false;
    return !(isIOS && hasNotificationBlock);
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String?;
    final body = notification?.body ?? message.data['body'] as String?;
    pushLog.info('foreground message', message.messageId);

    final localCopy = needsLocalCopy(
      isIOS: Platform.isIOS,
      hasNotificationBlock: notification != null,
      title: title,
      body: body,
    );
    if (!localCopy) pushLog.info('foreground: no local copy', message.messageId);
    if (localCopy) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: (message.messageId ?? '${DateTime.now().microsecondsSinceEpoch}')
                  .hashCode &
              0x7fffffff,
          channelKey: kDefaultChannelId,
          title: title ?? 'Bai Market',
          body: body ?? '',
          payload: message.data.map((k, v) => MapEntry(k, v?.toString())),
          notificationLayout: NotificationLayout.Default,
        ),
      );
    }
    // Сообщаем приложению: список уведомлений и бейдж на колокольчике должны
    // обновиться.
    PushEvents.notify();
  }

  static Future<void> _handleNotificationOpened(RemoteMessage message) =>
      PushMessageRouter.handleTap(message.data);

  static Map<String, dynamic> _payloadOf(ReceivedAction action) =>
      Map<String, dynamic>.from(action.payload ?? const {});

  @pragma('vm:entry-point')
  static Future<void> _onNotificationCreated(
    ReceivedNotification notification,
  ) async {
    pushLog.info('notification created', '${notification.id}');
  }

  @pragma('vm:entry-point')
  static Future<void> _onNotificationDisplayed(
    ReceivedNotification notification,
  ) async {
    pushLog.info('notification displayed', '${notification.id}');
  }

  @pragma('vm:entry-point')
  static Future<void> _onDismissActionReceived(ReceivedAction action) async {
    pushLog.info('notification dismissed', '${action.id}');
  }
}

/// Тап по уведомлению, созданному приложением.
///
/// Top-level и `@pragma('vm:entry-point')` — может быть вызван из фонового
/// изолята.
@pragma('vm:entry-point')
Future<void> onNotificationActionReceived(ReceivedAction action) async {
  final payload = Map<String, dynamic>.from(action.payload ?? const {});
  await PushMessageRouter.handleTap(payload);
  PushEvents.notify();
}
