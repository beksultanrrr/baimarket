import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_pallete.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../catalog/data/models/category_product_model.dart';
import '../../../collection/presentation/cubit/collection_cubit.dart';
import '../../../product/data/models/product_model.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../cubit/favorites_cubit.dart';
import '../widgets/favorites_empty_state.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FavoritesCubit _favCubit = FavoritesCubit();
  final CollectionCubit _recCubit = CollectionCubit();

  @override
  void initState() {
    super.initState();
    _favCubit.getFavorites();
    _recCubit.getCollection(slug: 'all', sort: 'popular');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider.value(
      value: _favCubit,
      child: Scaffold(
        backgroundColor: lightGray,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: () => context.pop(),
                      child: SvgPicture.asset(
                        'assets/icons/arrow_left.svg',
                        width: 24,
                        height: 24,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 48),
                          child: Text(
                            l10n.favorites,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                              fontFamily: 'Gilroy',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BlocConsumer<FavoritesCubit, FavoritesState>(
                  listener: (context, state) {
                    if (state is FavoritesDeleted ||
                        state is FavoritesAdded) {
                      _favCubit.getFavorites();
                      context.read<ProfileCubit>().getProfileData();
                    }
                  },
                  builder: (context, state) {
                    if (state is FavoritesGot) {
                      if (state.favorites.isEmpty) {
                        return _EmptyView(recCubit: _recCubit);
                      }
                      return _GridView(favorites: state.favorites);
                    }
                    if (state is FavoritesGetError) {
                      return _EmptyView(recCubit: _recCubit);
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

CategoryProductModel _asCategoryProduct(ProductModel p) {
  return CategoryProductModel(
    id: p.id,
    name: p.name,
    price: p.price,
    oldPrice: p.oldPrice,
    photoUrls: p.photoUrls,
    inStockCount: p.inStockCount,
    descriptionKz: p.descriptionKz,
    descriptionRu: p.descriptionRu,
    descriptionEn: p.descriptionEn,
    collections: p.collections,
    isInFavorite: true,
  );
}

class _GridView extends StatelessWidget {
  const _GridView({required this.favorites});
  final List<dynamic> favorites;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.54,
      ),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final fav = favorites[index];
        return ProductCard(product: _asCategoryProduct(fav.models));
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.recCubit});
  final CollectionCubit recCubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: FavoritesEmptyState(),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              l10n.recommended,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
          const SizedBox(height: 12),
          BlocBuilder<CollectionCubit, CollectionState>(
            bloc: recCubit,
            builder: (context, state) {
              if (state is CollectionGot) {
                final products = state.collection.products;
                if (products.isEmpty) return const SizedBox.shrink();
                final count = products.length > 10 ? 10 : products.length;
                return SizedBox(
                  height: 342,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: count,
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: 180,
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: index == count - 1 ? 0 : 10,
                          ),
                          child: ProductCard(product: products[index]),
                        ),
                      );
                    },
                  ),
                );
              }
              if (state is CollectionGetError) {
                return const SizedBox.shrink();
              }
              return const SizedBox(
                height: 320,
                child: Center(child: CircularProgressIndicator()),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
