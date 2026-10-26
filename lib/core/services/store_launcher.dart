import 'dart:io' show Platform;

import 'package:url_launcher/url_launcher.dart';

import '../services/app_logger.dart';
import '../urls.dart';

/// Открывает карточку приложения в «своём» магазине: Android → Google Play,
/// iOS → App Store.
///
/// На каждой платформе две попытки. Сначала нативная схема (`market://`,
/// `itms-apps://`) — она открывает приложение магазина сразу на нужной
/// карточке, минуя браузер и цепочку редиректов. Если магазина нет (кастомная
/// прошивка, симулятор, Huawei без GMS) — уходим на https-ссылку, которую
/// откроет браузер.
///
/// Возвращает `false`, если не сработало ничего: вызывающий код показывает
/// пользователю ссылку, а не молча гасит нажатие.
Future<bool> openAppStorePage({String? overrideUrl}) async {
  final candidates = <Uri>[];

  if (overrideUrl != null && overrideUrl.trim().isNotEmpty) {
    final parsed = Uri.tryParse(overrideUrl.trim());
    if (parsed != null && parsed.hasScheme) {
      // Ссылку из манифеста пробуем первой: она может вести на конкретный
      // трек или на другую страну.
      candidates.add(parsed);
    }
  }

  if (Platform.isAndroid) {
    // playListingId, а не applicationId сборки: в Play опубликован другой
    // пакет, страница сборочного отдаёт 404. Подробности — в urls.dart.
    candidates.add(Uri.parse('market://details?id=$playListingId'));
    candidates.add(Uri.parse(playStoreUrl));
  } else if (Platform.isIOS) {
    candidates.add(Uri.parse('itms-apps://apps.apple.com/app/id$appStoreId'));
    candidates.add(Uri.parse(appStoreUrl));
  }

  for (final uri in candidates) {
    try {
      // canLaunchUrl намеренно не спрашиваем: на Android 11+ он отвечает
      // `false` для всего, что не перечислено в <queries>, и честный
      // launchUrl отработал бы там, где проверка уже сказала «нельзя».
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (ok) {
        updateLog.nav('store opened', uri.scheme);
        return true;
      }
    } catch (e) {
      updateLog.warn('store launch failed', '$uri · $e');
    }
  }
  updateLog.error('no store handler', candidates.join(', '));
  return false;
}
