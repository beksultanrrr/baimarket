import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_route_observer.dart';
import '../../../../core/routing/app_routing.dart';
import '../../../../core/ui/bottom_bar_metrics.dart';
import '../../../live/presentation/widgets/live_shopping_scope.dart';
import '../../../menu/presentation/providers/bottom_nav_provider.dart';
import '../cubit/cart_cubit.dart';
import 'cart_floating_bar.dart';

/// Экраны, на которых плашка корзины имеет смысл.
///
/// Список разрешающий, а не запрещающий: так новый маршрут не унаследует
/// плашку случайно и не наложится на собственную нижнюю панель.
const _allowedRoutes = <String>{
  '/main',
  '/catalog',
  '/cart',
  '/profile',
  '/live/:id',
  '/live_host/:id',
  // Из сториз тоже можно положить товар в корзину, и плашка — единственное
  // подтверждение, что он туда попал.
  'stories_viewer',
  '/search',
  '/collection/:slug',
  '/raffle/:id',
  '/seller/:id',
  '/favorites',
};

/// Маршруты `MenuPage` — на них плашка встаёт над навигационной пилюлей и
/// прячется, когда открыт сам таб корзины.
const _menuRoutes = <String>{'/main', '/catalog', '/cart', '/profile'};

/// Чистая функция — вынесена отдельно, чтобы матрицу видимости можно было
/// проверить тестом без поднятия дерева виджетов.
bool shouldShowCartBar({
  required AppRouteInfo route,
  required int menuTabIndex,
  required int itemsCount,
  required bool keyboardOpen,
}) {
  if (itemsCount <= 0) return false;
  if (keyboardOpen) return false;
  // Сверху модальный шит. Плашка живёт над навигатором и иначе легла бы
  // поверх шита и его затемнения.
  if (route.isModal) return false;
  final name = route.name;
  if (name == null || !_allowedRoutes.contains(name)) return false;
  if (_menuRoutes.contains(name) && menuTabIndex == kMenuTabCart) return false;
  return true;
}

/// Оборачивает всё приложение и подмешивает плашку корзины поверх контента.
///
/// Монтируется в `MaterialApp.builder` — единственной точке выше навигатора
/// роутера, поэтому плашка переживает любой `push` и видна в том числе на
/// странице эфира.
class CartFloatingBarHost extends StatefulWidget {
  const CartFloatingBarHost({super.key, required this.child});

  final Widget child;

  @override
  State<CartFloatingBarHost> createState() => _CartFloatingBarHostState();
}

class _CartFloatingBarHostState extends State<CartFloatingBarHost> {
  @override
  void initState() {
    super.initState();
    // Иначе на холодном старте счётчик пустой до первого захода в корзину.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CartCubit>().ensureLoaded();
    });
  }

  /// Экраны, с которых нельзя пушить маршрут: под ними живёт WebRTC-сессия
  /// или проигрывается сториз, и push их снесёт.
  ///
  /// Сравнение идёт с шаблоном маршрута (`/live/:id`), а не с готовым путём —
  /// именно шаблон кладёт go_router в `RouteSettings.name`.
  bool get _onLive {
    final name = appRouteObserver.top.value.name;
    return name == '/live/:id' ||
        name == '/live_host/:id' ||
        name == 'stories_viewer';
  }

  void _openCart() {
    // На эфире нельзя пушить маршрут — стрим оборвётся. Открываем корзину
    // шитом поверх, как это делает сам экран эфира.
    if (_onLive) {
      final ctx = appRouteObserver.navigatorContext;
      if (ctx != null) {
        openLiveCartSheet(ctx);
        return;
      }
    }
    router.push('/cart'); // live-nav-ok: ветка вне эфира
  }

  Future<void> _checkout() async {
    final cart = await context.read<CartCubit>().prepareCheckout();
    // Корзина пуста или запрос не удался — сообщение уже показал
    // CartEventListener.
    if (cart == null || !mounted) return;
    final ctx = appRouteObserver.navigatorContext;
    if (_onLive && ctx != null && ctx.mounted) {
      LiveShoppingController().openCreateOrder(ctx, cart);
      return;
    }
    router.push('/make_order', extra: cart); // live-nav-ok: ветка вне эфира
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ValueListenableBuilder<AppRouteInfo>(
          valueListenable: appRouteObserver.top,
          builder: (context, route, _) {
            return Consumer(
              builder: (context, ref, __) {
                final tabIndex = ref.watch(bottomNavIndexProvider);
                return BlocBuilder<CartCubit, CartState>(
                  builder: (context, state) {
                    final got = state is CartGot ? state : null;
                    final itemsCount = got?.itemsCount ?? 0;
                    final keyboardOpen =
                        MediaQuery.of(context).viewInsets.bottom > 0;
                    final visible = shouldShowCartBar(
                      route: route,
                      menuTabIndex: tabIndex,
                      itemsCount: itemsCount,
                      keyboardOpen: keyboardOpen,
                    );

                    final thumbnails = <String>[];
                    for (final item in got?.cart.cartItems ?? const []) {
                      final photos = item.model?.photoUrls;
                      if (photos != null && photos.isNotEmpty) {
                        thumbnails.add(photos.first);
                      }
                      if (thumbnails.length == 3) break;
                    }

                    return Positioned(
                      left: kCartFloatingBarHMargin,
                      right: kCartFloatingBarHMargin,
                      bottom: cartBarBottomOffset(
                        context,
                        routeName: route.name,
                      ),
                      child: IgnorePointer(
                        ignoring: !visible,
                        child: AnimatedSlide(
                          offset: visible ? Offset.zero : const Offset(0, 1.6),
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: AnimatedOpacity(
                            opacity: visible ? 1 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: got == null
                                ? const SizedBox(
                                    height: kCartFloatingBarHeight,
                                  )
                                : CartFloatingBar(
                                    itemsCount: itemsCount,
                                    totalPrice: got.cart.totalPrice ?? 0,
                                    thumbnails: thumbnails,
                                    busy: got.busy,
                                    onOpenCart: _openCart,
                                    onCheckout: _checkout,
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}
