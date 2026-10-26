import '../../data/models/app_update_info.dart';

abstract class AppUpdateRepository {
  /// Возвращает решение об обновлении либо `null`, если проверить не удалось.
  ///
  /// `null` и «обновление не нужно» — разные вещи: во втором случае приходит
  /// [AppUpdateInfo] со `severity == none`. Различие нужно кубиту, чтобы не
  /// засчитывать сетевую ошибку за успешную проверку.
  Future<AppUpdateInfo?> checkForUpdate();
}
