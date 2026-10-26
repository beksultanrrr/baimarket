import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/app_update_cubit.dart';
import 'app_update_dialog.dart';

/// Оборачивает всё приложение и держит проверку версии.
///
/// Монтируется в `MaterialApp.builder` — там же, где [CartFloatingBarHost] и
/// `PushGate`. Это единственная точка выше навигатора роутера, и для
/// блокирующего диалога она принципиальна: карточка рисуется **слоем в дереве,
/// а не маршрутом**. У маршрута всегда остаются лазейки — `Navigator.pop` из
/// произвольного места, системное «назад», `router.go`, который подменяет весь
/// стек. Слой поверх навигатора не убирается ничем из этого: что бы ни
/// происходило с маршрутами внизу, оверлей остаётся на экране и перехватывает
/// все касания.
class AppUpdateGate extends StatefulWidget {
  const AppUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Не в `main()`: сетевая проверка там задержала бы снятие сплэша. Первый
    // кадр уже отрисован, поэтому диалог всплывает поверх интерфейса.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppUpdateCubit>().check(force: true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!mounted) return;
    // Приложение живёт в фоне неделями — без этого пользователь, который не
    // перезапускает его вручную, не узнает о релизе вообще. Частоту гейтит
    // сам кубит.
    context.read<AppUpdateCubit>().check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppUpdateCubit, AppUpdateState>(
      builder: (context, state) {
        final info = state.visibleUpdate;
        return Stack(
          children: [
            widget.child,
            if (info != null)
              Positioned.fill(
                child: _UpdateOverlay(
                  // Ключ по версии и строгости: смена рекомендованного на
                  // обязательное должна проиграть появление заново, а не
                  // подменить текст в уже показанной карточке.
                  key: ValueKey(
                    '${info.severity.name}:${info.latestVersion.raw}',
                  ),
                  onBarrierTap: info.isForced
                      ? null
                      : () => context.read<AppUpdateCubit>().snooze(),
                  child: AppUpdateDialog(
                    info: info,
                    onLater: () => context.read<AppUpdateCubit>().snooze(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Затемнение + появление карточки. Отдельный виджет, потому что анимация
/// входа не должна перезапускаться на каждый rebuild гейта.
class _UpdateOverlay extends StatefulWidget {
  const _UpdateOverlay({
    super.key,
    required this.onBarrierTap,
    required this.child,
  });

  final Widget child;

  /// `null` — тап по затемнению игнорируется (обязательное обновление).
  final VoidCallback? onBarrierTap;

  @override
  State<_UpdateOverlay> createState() => _UpdateOverlayState();
}

class _UpdateOverlayState extends State<_UpdateOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 0.92,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      // Material поверх голого builder-контекста: ниже по дереву Material есть
      // только внутри Scaffold-ов роутера, а карточке нужны свои чернила.
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // Затемнение и перехват касаний. `opaque` обязателен: без него
            // пустые места пропускают тапы на экран под оверлеем.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onBarrierTap,
                child: const ColoredBox(color: Color(0x8A000000)),
              ),
            ),
            ScaleTransition(scale: _scale, child: widget.child),
          ],
        ),
      ),
    );
  }
}
