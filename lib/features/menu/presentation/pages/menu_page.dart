// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:bai_market/core/app_pallete.dart';
import 'package:bai_market/core/auth/auth_gate.dart';
import 'package:bai_market/core/utils/count_format.dart';
import 'package:bai_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:bai_market/features/cart/presentation/pages/cart_page.dart';
import 'package:bai_market/features/catalog/presentation/pages/catalog_page.dart';
import 'package:bai_market/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../../catalog/presentation/widgets/catalog_top_switcher.dart';
import '../../../main/presentation/pages/main_page.dart';
import '../../../streams/presentation/pages/streams_page.dart';
import '../providers/bottom_nav_provider.dart';

class MenuPage extends ConsumerStatefulWidget {
  const MenuPage({super.key, required this.initialPage});
  final String initialPage;
  @override
  ConsumerState<MenuPage> createState() => _MainScreenState();
}

/// Размер таба нижней навигации — одинаковый для активного и неактивного
/// состояния. Ширина рассчитана так, чтобы пять табов помещались в ряд даже на
/// узких экранах (5 × 52 = 260 при ширине бара ~284 на 320-точечном экране).
const double _navPillWidth = 52;
const double _navPillHeight = 42;
const Duration _navAnimDuration = Duration(milliseconds: 220);

class _MainScreenState extends ConsumerState<MenuPage> {
  /// Контейнер, захваченный на монтировании: `ref` в `dispose` использовать
  /// нельзя, а вернуть таб нужно именно там.
  ProviderContainer? _container;

  /// Индекс, который был до нас, если этот `MenuPage` запушили поверх другого.
  int? _restoreIndexOnDispose;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _container ??= ProviderScope.containerOf(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    // Провайдер теперь общий (см. bottom_nav_provider.dart), поэтому начальный
    // таб пишем в post-frame: запись во время initState/build уронила бы
    // подписчиков ошибкой «modified a provider while widgets were building».
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // `/cart`, `/catalog`, `/profile` кладут новый MenuPage поверх уже
      // существующего. Запоминаем чужой таб, чтобы вернуть его при закрытии —
      // иначе после просмотра корзины нижний экран остался бы на её табе.
      if (Navigator.of(context).canPop()) {
        _restoreIndexOnDispose = ref.read(bottomNavIndexProvider);
      }
      ref.read(bottomNavIndexProvider.notifier).state =
          menuTabIndexFor(widget.initialPage);
    });
  }

  @override
  void dispose() {
    final restore = _restoreIndexOnDispose;
    if (restore != null) {
      _container?.read(bottomNavIndexProvider.notifier).state = restore;
    }
    super.dispose();
  }

  Widget _buildNavItem({
    required String asset,
    required int index,
    required WidgetRef ref,
    required bool active,
    required bool darkMode,
    int badgeCount = 0,
  }) {
    final requiresAuth = index == kMenuTabCart || index == kMenuTabProfile;
    return CupertinoButton(
      // Пилюля ниже фиксированной высоты, чтобы таб не «прыгал» при
      // переключении; вертикальный padding добирает зону нажатия до бара.
      padding: const EdgeInsets.symmetric(vertical: 5),
      minSize: 0,
      onPressed: () async {
        HapticFeedback.selectionClick();
        if (requiresAuth) {
          final ok = await ensureAuthenticated(context);
          if (!ok) return;
        }
        ref.read(bottomNavIndexProvider.notifier).update((state) => index);
      },
      child: _withBadge(
        badgeCount,
        _navPill(
          active: active,
          darkMode: darkMode,
          child: AnimatedScale(
            scale: active ? 1 : 0.92,
            duration: _navAnimDuration,
            curve: Curves.easeOut,
            child: _navIcon(asset, _navIconColor(active: active, darkMode: darkMode)),
          ),
        ),
      ),
    );
  }

  /// Активный таб — «стеклянная» пилюля, неактивный — та же коробка без фона.
  /// Размер одинаковый в обоих состояниях: иначе ширина ряда меняется на
  /// каждом переключении и соседние иконки заметно съезжают.
  Widget _navPill({
    required bool active,
    required bool darkMode,
    required Widget child,
  }) {
    if (!active) {
      return SizedBox(
        width: _navPillWidth,
        height: _navPillHeight,
        child: Center(child: child),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: _navPillWidth,
          height: _navPillHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(darkMode ? 0.22 : 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(darkMode ? 0.25 : 0.7),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  /// Иконки монохромные (`currentColor`), состояние задаётся только цветом:
  /// активный — в полную силу, неактивный — приглушённый под фон бара.
  /// На «Эфирах» бар тёмный, и чёрный по нему не читается, поэтому там
  /// та же логика, но в белом.
  Color _navIconColor({required bool active, required bool darkMode}) {
    final base = darkMode ? Colors.white : const Color(0xFF171717);
    if (active) return base;
    return base.withOpacity(darkMode ? 0.55 : 0.42);
  }

  /// Цифра над иконкой. `clipBehavior: none`, иначе бейдж обрежется краем.
  Widget _withBadge(int count, Widget child) {
    if (count <= 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        // Правый верхний угол самой иконки внутри пилюли 52×42.
        Positioned(
          right: 8,
          top: 4,
          child: AnimatedScale(
            scale: 1,
            duration: const Duration(milliseconds: 180),
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: mainColorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  formatCountShort(count),
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Цвет перегоняем твином, а не подменяем ассет: переключение таба тогда не
  /// мигает, а плавно перекрашивается.
  Widget _navIcon(String asset, Color color) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: color),
      duration: _navAnimDuration,
      curve: Curves.easeOut,
      builder: (context, value, _) => SvgPicture.asset(
        asset,
        height: 24,
        width: 24,
        colorFilter: ColorFilter.mode(value ?? color, BlendMode.srcIn),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Consumer(
        builder: (context, ref, child) {
          final currentIndex = ref.watch(bottomNavIndexProvider);
          return IndexedStack(
            index: currentIndex,
            children: [
              MainPage(
                onAllCatalog: () {
                  // Плитка «Весь Каталог» на главной → переключаем
                  // bottom-nav на таб «Каталог» и сразу открываем
                  // подвкладку «Весь каталог» (frame 16271).
                  ref.read(catalogTopTabProvider.notifier).state = CatalogTopTab.wholeCatalog;
                  ref.read(bottomNavIndexProvider.notifier).update((state) => 2);
                },
              ),
              const StreamsPage(),
              CatalogPage(),
              CartPage(
                toCatalog: () {
                  ref.read(bottomNavIndexProvider.notifier).update((state) => 2);
                },
              ),
              ProfilePage(),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer(
        builder: (context, ref, child) {
          final currentIndex = ref.watch(bottomNavIndexProvider);
          final darkMode = currentIndex == 1; // «Эфиры» — тёмный контент
          final barColor = darkMode ? const Color(0xFF1C1C1E).withOpacity(0.55) : Colors.white.withOpacity(0.5);
          final borderColor = darkMode ? Colors.white.withOpacity(0.20) : Colors.black.withOpacity(0.12);

          return Padding(
            padding: EdgeInsets.only(left: 18, right: 18, top: 4, bottom: MediaQuery.of(context).padding.bottom + 8),
            child: DecoratedBox(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(47), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8))]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(47),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    height: 57,
                    decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(47), border: Border.all(color: borderColor, width: 1.5)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                          asset: 'assets/icons/main_menu/nav_home.svg',
                          index: kMenuTabHome,
                          ref: ref,
                          active: currentIndex == kMenuTabHome,
                          darkMode: darkMode,
                        ),
                        _buildNavItem(
                          asset: 'assets/icons/main_menu/nav_live.svg',
                          index: kMenuTabStreams,
                          ref: ref,
                          active: currentIndex == kMenuTabStreams,
                          darkMode: darkMode,
                        ),
                        _buildNavItem(
                          asset: 'assets/icons/main_menu/nav_catalog.svg',
                          index: kMenuTabCatalog,
                          ref: ref,
                          active: currentIndex == kMenuTabCatalog,
                          darkMode: darkMode,
                        ),
                        BlocBuilder<CartCubit, CartState>(
                          builder: (context, cartState) => _buildNavItem(
                            asset: 'assets/icons/main_menu/nav_cart.svg',
                            index: kMenuTabCart,
                            ref: ref,
                            active: currentIndex == kMenuTabCart,
                            darkMode: darkMode,
                            badgeCount: cartState is CartGot
                                ? cartState.itemsCount
                                : 0,
                          ),
                        ),
                        _buildNavItem(
                          asset: 'assets/icons/main_menu/nav_box.svg',
                          index: kMenuTabProfile,
                          ref: ref,
                          active: currentIndex == kMenuTabProfile,
                          darkMode: darkMode,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
