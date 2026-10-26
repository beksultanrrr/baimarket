import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

/// Канал уведомлений.
///
/// Тот же ключ прописан в `AndroidManifest.xml` как
/// `com.google.firebase.messaging.default_notification_channel_id` и создаётся
/// нативно в `MainActivity.onCreate`. Три определения обязаны совпадать: важность
/// фиксируется при первом создании канала и потом не меняется.
const String kDefaultChannelId = 'default_channel';
const String kDefaultChannelName = 'Основные уведомления';
const String kDefaultChannelDescription =
    'Канал для основных уведомлений приложения';
const Color kNotificationColor = Color(0xFF71CD32);

NotificationChannel buildDefaultChannel() => NotificationChannel(
      channelKey: kDefaultChannelId,
      channelName: kDefaultChannelName,
      channelDescription: kDefaultChannelDescription,
      defaultColor: kNotificationColor,
      ledColor: kNotificationColor,
      importance: NotificationImportance.High,
      channelShowBadge: true,
      enableVibration: true,
      enableLights: true,
      playSound: true,
    );
