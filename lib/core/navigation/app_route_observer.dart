import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Что сейчас на вершине стека навигации.
class AppRouteInfo {
  const AppRouteInfo({this.name, this.isModal = false, this.depth = 0});

  static const none = AppRouteInfo();

  /// Для страниц go_router это **шаблон** маршрута: `/cart`, `/product/:id`.
  final String? name;

  /// Сверху лежит модалка — шит или диалог.
  final bool isModal;

  final int depth;

  @override
  String toString() => 'AppRouteInfo(name: $name, isModal: $isModal)';

  @override
  bool operator ==(Object other) =>
      other is AppRouteInfo &&
      other.name == name &&
      other.isModal == isModal &&
      other.depth == depth;

  @override
  int get hashCode => Object.hash(name, isModal, depth);
}

/// Наблюдатель за навигацией приложения.
///
/// Нужен виджетам, которые живут **выше** роутера (в `MaterialApp.builder`) и
/// поэтому не могут спросить `GoRouterState.of(context)`.
///
/// Признак «сверху модалка» определяется как `route is PopupRoute` — этого
/// достаточно: так помечены и шиты лайв-шопинга, и шит логина, и подарки, и
/// Kaspi. Виджету поверх роутера это критично: он рисуется над оверлеем
/// навигатора и иначе лёг бы поверх шита вместе с его затемнением.
class AppRouteObserver extends NavigatorObserver {
  final ValueNotifier<AppRouteInfo> top =
      ValueNotifier<AppRouteInfo>(AppRouteInfo.none);

  final List<Route<dynamic>> _stack = [];

  /// Контекст внутри навигатора — нужен, чтобы из виджета над роутером открыть
  /// модальный шит (например, корзину поверх идущего эфира).
  BuildContext? get navigatorContext => navigator?.context;

  AppRouteInfo? _pending;

  void _sync() {
    final route = _stack.isEmpty ? null : _stack.last;
    final next = route == null
        ? AppRouteInfo.none
        : AppRouteInfo(
            name: route.settings.name,
            isModal: route is PopupRoute,
            depth: _stack.length,
          );

    // Навигатор уведомляет обсерверы синхронно — в том числе во время build
    // (например, при восстановлении стека в `didChangeDependencies`).
    // Слушатель `top` живёт выше роутера, в `MaterialApp.builder`, поэтому
    // синхронный `notifyListeners` там ловит «setState() during build».
    // Откладываем на конец кадра.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      final alreadyScheduled = _pending != null;
      _pending = next;
      if (alreadyScheduled) return;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        final value = _pending;
        _pending = null;
        if (value != null) top.value = value;
      });
      return;
    }

    _pending = null;
    top.value = next;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    _sync();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _sync();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _sync();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) _stack.remove(oldRoute);
    if (newRoute != null) _stack.add(newRoute);
    _sync();
  }
}
