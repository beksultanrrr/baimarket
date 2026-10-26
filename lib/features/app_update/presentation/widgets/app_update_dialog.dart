import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/app_pallete.dart';
import '../../../../core/services/store_launcher.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/app_update_info.dart';

/// Карточка обновления. Рисуется поверх всего приложения гейтом
/// [AppUpdateGate], а не через `showDialog`, поэтому про навигацию ничего не
/// знает и закрыть себя сама не может — за это отвечает [onLater].
class AppUpdateDialog extends StatefulWidget {
  const AppUpdateDialog({super.key, required this.info, required this.onLater});

  final AppUpdateInfo info;

  /// Нажали «Позже». У обязательного обновления кнопки нет, и колбэк не зовётся.
  final VoidCallback onLater;

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  bool _opening = false;
  bool _failed = false;

  Future<void> _openStore() async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _failed = false;
    });
    final ok = await openAppStorePage(overrideUrl: widget.info.storeUrl);
    if (!mounted) return;
    setState(() {
      _opening = false;
      // Ошибку показываем прямо в карточке: SnackBar ушёл бы под оверлей,
      // потому что ScaffoldMessenger живёт ниже по дереву.
      _failed = !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final info = widget.info;
    final forced = info.isForced;
    final notes = info.notesFor(Localizations.localeOf(context).languageCode);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          // Потолок по высоте, иначе длинный список «что нового» на маленьком
          // экране выдавил бы кнопку «Обновить» за пределы карточки.
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: Material(
            color: Colors.white,
            elevation: 0,
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _UpdateIcon(),
                  const SizedBox(height: 20),
                  _VersionPill(
                    label: l10n.updateVersionBadge(
                      info.latestVersion.raw.isEmpty
                          ? info.latestVersion.toString()
                          : info.latestVersion.raw,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    forced ? l10n.updateForcedTitle : l10n.updateRecommendedTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF17181C),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    forced
                        ? l10n.updateForcedMessage
                        : l10n.updateRecommendedMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8C8C8C),
                      height: 1.4,
                    ),
                  ),
                  if (notes != null) ...[
                    const SizedBox(height: 18),
                    _ReleaseNotes(title: l10n.updateWhatsNew, body: notes),
                  ],
                  if (_failed) ...[
                    const SizedBox(height: 14),
                    Text(
                      l10n.updateStoreOpenFailed,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFEC3A3A),
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  _PrimaryButton(
                    label: l10n.updateNow,
                    busy: _opening,
                    onPressed: _openStore,
                  ),
                  if (!forced) ...[
                    const SizedBox(height: 6),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      onPressed: _opening ? null : widget.onLater,
                      child: Text(
                        l10n.updateLater,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8C8C8C),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Круглая иконка со светло-зелёным ореолом — тот же приём, что у Plus-бейджа.
class _UpdateIcon extends StatelessWidget {
  const _UpdateIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      width: 88,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFEDFBE4),
      ),
      alignment: Alignment.center,
      child: Container(
        height: 64,
        width: 64,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: accentSoftGreen,
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.arrow_downward_rounded,
          size: 32,
          color: mainColorDark,
        ),
      ),
    );
  }
}

class _VersionPill extends StatelessWidget {
  const _VersionPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8C8C8C),
        ),
      ),
    );
  }
}

class _ReleaseNotes extends StatelessWidget {
  const _ReleaseNotes({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF17181C),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5C5C5C),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: busy ? null : onPressed,
        child: Container(
          decoration: BoxDecoration(
            color: busy ? mainColorLight.withValues(alpha: 0.6) : seconColor,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: busy
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
