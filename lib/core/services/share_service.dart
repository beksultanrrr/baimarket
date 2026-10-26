import 'dart:ui';

import 'package:share_plus/share_plus.dart';

/// Thin wrapper around share_plus. Keeps the UI layer free of plugin imports
/// and gives us a single seam to mock in tests or swap out later.
class ShareService {
  const ShareService();

  /// Opens the platform's native share sheet with [message].
  ///
  /// [sharePositionOrigin] is required on iPad to anchor the popover; on
  /// phones it can be left null.
  Future<ShareResult> share({
    required String message,
    Rect? sharePositionOrigin,
  }) {
    return Share.share(message, sharePositionOrigin: sharePositionOrigin);
  }

  /// Обратная совместимость для баннера-приглашения в профиле.
  Future<ShareResult> shareApp({
    required String message,
    Rect? sharePositionOrigin,
  }) =>
      share(message: message, sharePositionOrigin: sharePositionOrigin);
}
