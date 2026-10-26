import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../features/create_order/presentation/cubit/create_order_cubit.dart';
import '../../features/favorites/presentation/cubit/favorites_cubit.dart';
import '../../features/notification/presentation/cubit/notification_cubit.dart';
import '../../features/orders/presentation/cubit/orders_cubit.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../pin_storage.dart';
import '../push/push_token_sync.dart';
import '../routing/app_routing.dart';
import 'app_lock.dart';
import 'pending_action.dart';
import '../../features/profile/presentation/cubit/current_user_cubit.dart';
import '../../features/live/presentation/cubit/live_host_cubit.dart';

/// Centralized logout: drops the token, wipes user-specific cubit state,
/// clears any pending post-login action, and routes to /auth.
Future<void> signOutAndCleanup(BuildContext context) async {
  PendingAuthAction.clear();
  // Строго до logOut(): тот стирает Bearer, который нужен для запроса.
  // Без этого на сервере копится по строке регистрации на каждый выход.
  await PushTokenSync.unregisterOnLogout();
  if (!context.mounted) return;
  resetUserCubits(context);
  await context.read<AuthCubit>().logOut();
  await removePin();
  AppLock.lock();
  router.go('/auth');
}

/// Resets every user-specific cubit registered at app root so leftover state
/// from the previous user doesn't leak into the next session.
void resetUserCubits(BuildContext context) {
  context.read<CartCubit>().reset();
  context.read<ProfileCubit>().reset();
  context.read<CurrentUserCubit>().reset();
  context.read<LiveHostCubit>().reset();
  context.read<FavoritesCubit>().reset();
  context.read<OrdersCubit>().reset();
  context.read<NotificationCubit>().reset();
  context.read<CreateOrderCubit>().reset();
}
