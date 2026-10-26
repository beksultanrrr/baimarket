import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/notification/presentation/cubit/notification_cubit.dart';
import '../firebase_service.dart';
import '../secure_token_storage.dart';
import 'push_events.dart';
import 'push_message_router.dart';
import 'push_token_sync.dart';

/// Оборачивает приложение и владеет жизненным циклом пушей.
///
/// Зачем отдельный виджет: сетевую часть инициализации нельзя делать в
/// `main()` — она держала бы сплэш; а повторы регистрации токена надо
/// привязать к возврату приложения на передний план.
class PushGate extends StatefulWidget {
  const PushGate({super.key, required this.child});

  final Widget child;

  @override
  State<PushGate> createState() => _PushGateState();
}

class _PushGateState extends State<PushGate> with WidgetsBindingObserver {
  StreamSubscription<void>? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = PushEvents.stream.listen((_) => _refreshNotifications());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Разрешение спрашиваем здесь, а не в `main()`: первый кадр уже
      // отрисован, поэтому системный диалог всплывает поверх интерфейса, а не
      // поверх сплэша.
      //
      // Вызова не было вообще — метод существовал, но его никто не звал.
      // Последствия: на Android 13+ без POST_NOTIFICATIONS уведомления не
      // показываются, а на iOS без авторизации не выдаётся даже APNs-токен,
      // то есть регистрация ниже была обречена. Порядок важен: сначала
      // разрешение, потом токен.
      await FirebaseMessagingService.requestPermissionIfNeeded();
      if (!mounted) return;
      await FirebaseMessagingService.initAfterUi();
      // Маршрут из тапа, который случился до готовности роутера.
      PushMessageRouter.drainPending();
      await _refreshNotifications();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Пользователь мог включить уведомления в системных настройках, а прошлая
    // попытка регистрации — упасть.
    PushTokenSync.onAppResume();
    _refreshNotifications();
  }

  Future<void> _refreshNotifications() async {
    if (!mounted) return;
    // Гостю запрос не шлём: appDio отклонит его синтетическим 401.
    if (await getAuthToken() == null) return;
    if (!mounted) return;
    await context.read<NotificationCubit>().refresh();
  }

  @override
  void dispose() {
    _sub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
