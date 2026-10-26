import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/models/live_host_args.dart';
import '../../domain/repositories/live_repository.dart';
import '../../live_flags.dart';
import '../cubit/live_host_cubit.dart';
import 'stream_already_live_dialog.dart';

const int kStreamTitleMinLength = 3;
const int kStreamTitleMaxLength = 60;

/// Шит «Новый эфир»: название и старт.
///
/// Обложка (`coverUrl` в `POST /live/start`) — это имя файла в MinIO, а ручки,
/// куда его заливать, в контракте нет. До ответа бэка поле выключено флагом
/// [kStreamCoverUploadEnabled], карточка в ленте падает на фото закреплённого
/// товара.
Future<void> showStartStreamSheet({
  required BuildContext context,
  required LiveHostCubit cubit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => BlocProvider.value(
      value: cubit,
      child: const _StartStreamSheet(),
    ),
  );
}

class _StartStreamSheet extends StatefulWidget {
  const _StartStreamSheet();

  @override
  State<_StartStreamSheet> createState() => _StartStreamSheetState();
}

class _StartStreamSheetState extends State<_StartStreamSheet> {
  final _title = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final title = _title.text.trim();
    if (title.length < kStreamTitleMinLength) {
      setState(() => _error = l10n.startStreamTitleTooShort);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    // Разрешения спрашиваем ДО создания эфира. Иначе на сервере повиснет
    // «зомби»: стрим создан, вещать в него человек не может, и разгребать это
    // придётся через 409 при следующей попытке.
    final granted = await _ensureCapturePermissions();
    if (!mounted) return;
    if (!granted) {
      setState(() => _submitting = false);
      await _showPermissionDialog();
      return;
    }

    final cubit = context.read<LiveHostCubit>();
    final result = await cubit.start(title: title);
    if (!mounted) return;
    setState(() => _submitting = false);

    switch (result) {
      case LiveStartOk(:final data):
        Navigator.of(context).pop();
        // live-nav-ok: экран ведущего — полноэкранный, не шит
        context.push(
          '/live_host/${data.stream.id}',
          extra: LiveHostArgs.fromStartResponse(data),
        );
      case LiveStartForbidden():
        Navigator.of(context).pop();
        await showStreamAccessDeniedDialog(context);
      case LiveStartConflict(:final streamId):
        Navigator.of(context).pop();
        if (streamId != null) {
          await showStreamAlreadyLiveDialog(
            context: context,
            cubit: cubit,
            streamId: streamId,
            title: title,
          );
        }
      case LiveStartUnauthorized():
        Navigator.of(context).pop();
      case LiveStartFailed():
        // Шит не закрываем: набранное название должно уцелеть.
        setState(() => _error = l10n.startStreamFailed);
    }
  }

  /// Камера и микрофон. `Permission.camera`/`microphone` на обеих платформах
  /// сводятся к системным запросам, которые нужны flutter_webrtc.
  Future<bool> _ensureCapturePermissions() async {
    final statuses = await [Permission.camera, Permission.microphone].request();
    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }

  Future<void> _showPermissionDialog() async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.hostPermissionDeniedTitle),
        content: Text(l10n.hostPermissionDeniedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              openAppSettings();
            },
            child: Text(l10n.hostOpenSettings),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + mq.padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.startStreamSheetTitle,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.startStreamTitleLabel,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _title,
                enabled: !_submitting,
                autofocus: true,
                cursorColor: Colors.white,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(kStreamTitleMaxLength),
                ],
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: l10n.startStreamTitleHint,
                  hintStyle: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _submit(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 13,
                  color: Color(0xFFFF6B6B),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _submitting ? null : _submit,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD40176), Color(0xFFEC37CE)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n.startStreamSubmit,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 403 — доступ к эфирам не выдан либо аккаунт продавца отключён.
///
/// Именно диалог, а не SnackBar: SnackBar под модальным шитом на этой странице
/// просто не виден.
Future<void> showStreamAccessDeniedDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      content: Text(l10n.streamAccessDenied),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(),
          child: Text(l10n.commonCancel),
        ),
      ],
    ),
  );
}
