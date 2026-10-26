import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_gate.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/presentation/cubit/current_user_cubit.dart';
import '../cubit/live_host_cubit.dart';
import 'start_stream_sheet.dart';

/// Кнопка «Начать эфир» сверху на вкладке «Эфиры».
///
/// Видна только продавцам — роль берётся из `GET /users/me/profile`
/// (`CurrentUserCubit`). Ни покупателю, ни админу кнопки нет: эфир по
/// контракту ведёт `SELLER`, админ лишь выдаёт ему доступ в админке. Раньше
/// кнопку показывали всем, и человек узнавал об отказе только после того, как
/// ввёл название и выдал доступ к камере.
///
/// Гейт по роли — про видимость, а не про права. Право вещать по-прежнему
/// решает сервер ответом на `POST /live/start`: у продавца может не быть
/// выданного админом доступа к эфирам, и в этой ручке такого поля нет. Разбор
/// 403/409 остаётся на месте как страховка.
///
/// Второе состояние — «Вернуться в свой эфир»: если `GET /live/my` показал
/// активный эфир, создавать второй нельзя.
class StartStreamButton extends StatelessWidget {
  const StartStreamButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<CurrentUserCubit, CurrentUserState>(
      builder: (context, user) {
        if (!user.canOpenStreaming) return const SizedBox.shrink();
        return _Button(l10n: l10n);
      },
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LiveHostCubit, LiveHostState>(
      builder: (context, state) {
        final active = state.activeStream;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: SizedBox(
            height: 44,
            width: double.infinity,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: state.isBusy
                  ? null
                  : () => active == null
                      ? _startNew(context)
                      // live-nav-ok: полноэкранный вход в свой эфир
                      : context.push('/live_host/${active.id}'),
              child: Opacity(
                opacity: state.isBusy ? 0.6 : 1,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD40176), Color(0xFFEC37CE)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/stream/live_sun.svg',
                        width: 18,
                        height: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        active == null
                            ? l10n.streamStartCta
                            : l10n.streamResumeCta,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _startNew(BuildContext context) async {
    final cubit = context.read<LiveHostCubit>();
    // Без pendingAction: шит нельзя безопасно переиграть из контекста, который
    // к моменту возврата с авторизации уже размонтирован.
    final ok = await ensureAuthenticated(context);
    if (!ok || !context.mounted) return;
    await showStartStreamSheet(context: context, cubit: cubit);
  }
}
