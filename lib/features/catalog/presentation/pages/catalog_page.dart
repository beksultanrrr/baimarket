import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../seller/presentation/cubit/seller_list_cubit.dart';
import '../../../seller/presentation/widgets/seller_banners.dart';
import '../widgets/catalog_app_bar.dart';
import '../widgets/catalog_tiles_grid.dart';
import '../widgets/catalog_top_switcher.dart';

class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({super.key});

  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  final SellerListCubit _sellerListCubit = SellerListCubit();

  @override
  void initState() {
    super.initState();
    _sellerListCubit.load();
  }

  @override
  void dispose() {
    _sellerListCubit.close();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await _sellerListCubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topTab = ref.watch(catalogTopTabProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: BlocProvider.value(
          value: _sellerListCubit,
          child: AppRefreshIndicator(
            onRefresh: _onRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                const SliverToBoxAdapter(child: CatalogAppBar()),
                SliverToBoxAdapter(
                  child: CatalogTopSwitcher(
                    selected: topTab,
                    onChanged: (tab) {
                      if (topTab == tab) return;
                      ref.read(catalogTopTabProvider.notifier).state = tab;
                    },
                    allShopsLabel: l10n.allShopsTab,
                    wholeCatalogLabel: l10n.wholeCatalogTab,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(child: _body(topTab)),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(CatalogTopTab topTab) {
    // «Все магазины» — карточки продавцов из GET /seller.
    // «Весь каталог» — сетка категорий-плиток (новый дизайн); тап
    // ведёт на /collection/{slug} (с фолбэком на `all`).
    final Widget child = topTab == CatalogTopTab.allShops
        ? const KeyedSubtree(
            key: ValueKey('allShops'),
            child: SellerBanners(
              padding: EdgeInsets.symmetric(horizontal: 16),
            ),
          )
        : const KeyedSubtree(
            key: ValueKey('wholeCatalog'),
            child: CatalogTilesGrid(),
          );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: child,
    );
  }
}
