import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../firebase_options.dart';
import '../services/app_logger.dart';
import 'push_channels.dart';

/// Обработчик пушей в фоне и в убитом приложении.
///
/// Обязан быть top-level и помечен `@pragma('vm:entry-point')` — иначе
/// tree-shaking выкинет его из release-сборки.
///
/// Раньше он только печатал `messageId`. Последствие: **data-only** пуш
/// (без блока `notification`) не давал вообще ничего видимого ни на одной
/// платформе.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Это отдельный изолят — Firebase в нём ещё не инициализирован.
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // Если пуш пришёл с блоком `notification`, системный трей его уже показал.
    // Создавать своё уведомление здесь — значит удвоить каждый пуш. Это самый
    // вероятный способ сделать хуже, чем было.
    if (message.notification != null) {
      pushLog.info('background: tray notification', message.messageId);
      return;
    }

    final data = message.data;
    final title = data['title'] as String?;
    final body = data['body'] as String?;
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      pushLog.info('background: data-only without title/body — skipped');
      return;
    }

    // AWN в этом изоляте тоже ещё не инициализирован.
    await AwesomeNotifications().initialize(
      null,
      [buildDefaultChannel()],
      debug: false,
    );

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        // Стабильный положительный id: `message.hashCode` — identity-хэш,
        // недетерминированный и может быть отрицательным.
        id: (message.messageId ?? DateTime.now().microsecondsSinceEpoch
                .toString())
            .hashCode &
            0x7fffffff,
        channelKey: kDefaultChannelId,
        title: title ?? 'Bai Market',
        body: body ?? '',
        payload: data.map((k, v) => MapEntry(k, v?.toString())),
        notificationLayout: NotificationLayout.Default,
      ),
    );
    pushLog.info('background: data-only notification shown');
  } catch (e, st) {
    pushLog.error('background handler failed', e.toString(), e, st);
  }
}
