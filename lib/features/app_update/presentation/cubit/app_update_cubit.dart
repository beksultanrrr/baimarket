import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/app_logger.dart';
import '../../data/datasources/app_update_services.dart';
import '../../data/datasources/app_update_storage.dart';
import '../../data/models/app_update_info.dart';
import '../../domain/repositories/app_update_repository.dart';

part 'app_update_state.dart';

/// Как часто перепроверяем версию при возврате приложения на передний план.
/// Чаще незачем: релизы не выходят раз в минуту, а каждый повтор — сетевой
/// запрос на старте.
const Duration _kRecheckInterval = Duration(hours: 4);

class AppUpdateCubit extends Cubit<AppUpdateState> {
  AppUpdateCubit({AppUpdateRepository? repository})
    : _repository = repository ?? AppUpdateServices(),
      super(const AppUpdateInitial());

  final AppUpdateRepository _repository;

  bool _inFlight = false;
  DateTime? _lastCheckedAt;

  /// Обязательное обновление показано — дальше кубит заморожен.
  ///
  /// Без этого флага любая следующая проверка (возврат из фона, сеть отвалилась)
  /// могла бы вернуть `null` и снять блокирующий диалог. Единственный выход из
  /// этого состояния — установить новую версию.
  bool get isLocked => state.visibleUpdate?.isForced == true;

  /// Проверка версии.
  ///
  /// [force] игнорирует интервал между проверками — им пользуется первый
  /// запуск. Возврат из фона ходит без него.
  Future<void> check({bool force = false}) async {
    if (isLocked || _inFlight) return;
    if (!force && _lastCheckedAt != null) {
      final since = DateTime.now().difference(_lastCheckedAt!);
      if (since < _kRecheckInterval && !since.isNegative) return;
    }

    _inFlight = true;
    if (state is AppUpdateInitial) emit(const AppUpdateChecking());
    try {
      final info = await _repository.checkForUpdate();
      _lastCheckedAt = DateTime.now();

      if (info == null || info.severity == AppUpdateSeverity.none) {
        _safeEmit(const AppUpdateNotRequired());
        return;
      }

      // «Позже» действует только на рекомендованные. Обязательное показываем
      // всегда — на то оно и обязательное.
      if (info.severity == AppUpdateSeverity.recommended &&
          await isUpdateSnoozed(info.latestVersion.raw)) {
        updateLog.info('recommended отложено', info.latestVersion.raw);
        _safeEmit(const AppUpdateNotRequired());
        return;
      }

      updateLog.state('показываем диалог', info.severity.name);
      _safeEmit(AppUpdateRequired(info));
    } catch (e, st) {
      // Проверка обновления не имеет права ломать запуск: молча уходим в
      // «показывать нечего».
      updateLog.error('check failed', null, e, st);
      _safeEmit(const AppUpdateNotRequired());
    } finally {
      _inFlight = false;
    }
  }

  /// «Позже» под рекомендованным обновлением.
  Future<void> snooze() async {
    final info = state.visibleUpdate;
    if (info == null || info.isForced) return;
    await snoozeUpdate(info.latestVersion.raw);
    _safeEmit(const AppUpdateNotRequired());
  }

  void _safeEmit(AppUpdateState next) {
    if (isClosed) return;
    // Ещё один страховочный пояс: даже если состояние успело стать
    // блокирующим между await-ами, снять его нельзя.
    if (isLocked && next.visibleUpdate?.isForced != true) return;
    emit(next);
  }
}
