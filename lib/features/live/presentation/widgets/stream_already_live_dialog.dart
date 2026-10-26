import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/models/live_host_args.dart';
import '../../domain/repositories/live_repository.dart';
import '../cubit/live_host_cubit.dart';

/// Диалог на 409 от `POST /live/start`: у продавца уже идёт эфир.
///
/// Он же — путь восстановления после падения приложения: `POST /live/:id/stop`
/// при принудительном закрытии не успевает уйти, и на сервере остаётся живой
/// эфир, в который уже никто не вещает.
///
/// Оба действия ведут через один метод кубита, потому что здесь дыра в
/// контракте: **publisher-токен для уже идущего эфира получить неоткуда**.
/// `POST /live/start` отдаёт его только вместе с созданием нового эфира, а
/// `POST /live/:id/token` — зрительский. Пока бэк не научится (role-aware
/// `/live/:id/token` либо отдельная ручка), «вернуться к вещанию» честно
/// невозможно: можно только завершить и начать заново либо смотреть свой эфир
/// как зритель.
Future<void> showStreamAlreadyLiveDialog({
  required BuildContext context,
  required LiveHostCubit cubit,
  required int streamId,
  required String title,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: Text(l10n.streamAlreadyLiveTitle),
      content: Text(l10n.streamAlreadyLiveMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(),
          child: Text(l10n.commonCancel),
        ),
        // Смотреть свой эфир: зрительский токен возьмёт LiveRoomCubit сам —
        // второго запроса токена здесь быть не должно.
        TextButton(
          onPressed: () {
            Navigator.of(dialogCtx).pop();
            // live-nav-ok: свой эфир открывается как обычный экран зрителя
            context.push('/live/$streamId');
          },
          child: Text(l10n.streamOpenAsViewer),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(dialogCtx).pop();
            final result = await cubit.restartStream(
              streamId: streamId,
              title: title,
            );
            if (!context.mounted) return;
            if (result case LiveStartOk(:final data)) {
              // live-nav-ok: возврат к вещанию — полноэкранный экран
              context.push(
                '/live_host/${data.stream.id}',
                extra: LiveHostArgs.fromStartResponse(data),
              );
            }
          },
          child: Text(l10n.streamEndAndRestart),
        ),
      ],
    ),
  );
}
