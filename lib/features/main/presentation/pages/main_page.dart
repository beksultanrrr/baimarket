import 'package:bai_market/features/collection/presentation/cubit/collection_cubit.dart';
import 'package:bai_market/features/main/presentation/cubit/main_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../core/widgets/shimmer.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_banner_carousel.dart';
import '../widgets/home_category_grid.dart';
import '../widgets/home_product_grid.dart';
import '../widgets/home_search_bar.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key, this.onAllCatalog});
  final VoidCallback? onAllCatalog;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final MainCubit _bannerCubit = MainCubit();
  final CollectionCubit _collectionCubit = CollectionCubit();
  static const String _slug = 'all';

  @override
  void initState() {
    super.initState();
    _collectionCubit.getCollection(slug: _slug, sort: 'popular');
  }

  @override
  void dispose() {
    _bannerCubit.close();
    _collectionCubit.close();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.wait([_bannerCubit.getBanners(), _collectionCubit.getCollection(slug: _slug, sort: 'popular')]);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Color(0xFFF7F7F7),
        body: Column(
          children: [
            const HomeAppBar(),
            Expanded(
              child: AppRefreshIndicator(
                onRefresh: _onRefresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    // Banner Carousel — локальные ассеты, без сетевой загрузки.
                    const SliverToBoxAdapter(child: HomeBannerCarousel()),

                    // Search Bar
                    const SliverToBoxAdapter(
                      child: Padding(padding: EdgeInsets.only(top: 24), child: HomeSearchBar()),
                    ),

                    // Category Grid
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: HomeCategoryGrid(onAllCatalog: widget.onAllCatalog),
                      ),
                    ),

                    // Recommended heading — заменили горизонтальные слаг-табы
                    // одной статичной подписью; коллекция всегда грузится для
                    // slug='all' (см. _slug).
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Text(
                          AppLocalizations.of(context)!.recommended,
                          style: const TextStyle(fontFamily: 'Gilroy', fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black),
                        ),
                      ),
                    ),

                    // Product Grid
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 20),
                        child: BlocBuilder<CollectionCubit, CollectionState>(
                          bloc: _collectionCubit,
                          builder: (context, state) {
                            if (state is CollectionGot) {
                              return HomeProductGrid(products: state.collection.products);
                            }
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: 4,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.65),
                                itemBuilder: (context, index) {
                                  return SimpleShimmer(borderRadius: 16);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
