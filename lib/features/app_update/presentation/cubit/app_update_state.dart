part of 'app_update_cubit.dart';

abstract class AppUpdateState extends Equatable {
  const AppUpdateState();

  /// Что должен нарисовать гейт. `null` — ничего.
  AppUpdateInfo? get visibleUpdate => null;

  @override
  List<Object?> get props => [];
}

class AppUpdateInitial extends AppUpdateState {
  const AppUpdateInitial();
}

class AppUpdateChecking extends AppUpdateState {
  const AppUpdateChecking();
}

/// Проверка прошла, показывать нечего: версия свежая, разошёлся только PATCH,
/// рекомендованное обновление отложено — либо источник недоступен.
class AppUpdateNotRequired extends AppUpdateState {
  const AppUpdateNotRequired();
}

/// Есть что показать. Гейт рисует диалог по `info.severity`.
class AppUpdateRequired extends AppUpdateState {
  const AppUpdateRequired(this.info);

  final AppUpdateInfo info;

  @override
  AppUpdateInfo? get visibleUpdate => info;

  @override
  List<Object?> get props => [info.severity, info.latestVersion.raw];
}
