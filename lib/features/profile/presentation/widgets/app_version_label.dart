import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/app_pallete.dart';
import '../../../../l10n/app_localizations.dart';

/// Строка «Версия: 1.0.9» внизу профиля.
///
/// Номер берётся из `PackageInfo`, а не из константы: иначе он разъезжается
/// с тем, что реально стоит у пользователя, при каждом релизе.
///
/// Пока версия читается, строка не показывается — мигать плейсхолдером хуже,
/// чем появиться на кадр позже.
class AppVersionLabel extends StatefulWidget {
  const AppVersionLabel({super.key});

  @override
  State<AppVersionLabel> createState() => _AppVersionLabelState();
}

class _AppVersionLabelState extends State<AppVersionLabel> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = info.version);
    } catch (_) {
      // Платформа не отдала данные — просто не показываем строку.
    }
  }

  @override
  Widget build(BuildContext context) {
    final version = _version;
    if (version == null) return const SizedBox.shrink();

    // Column профиля центрирует детей, поэтому прижимаем строку влево явно —
    // по макету она идёт под «Выйти» по левому краю.
    return Container(
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        AppLocalizations.of(context)!.profileVersion(version),
        style: const TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: secondaryText,
        ),
      ),
    );
  }
}
