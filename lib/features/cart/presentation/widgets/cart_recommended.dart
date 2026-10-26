import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../collection/presentation/cubit/collection_cubit.dart';

class CartRecommended extends StatefulWidget {
  const CartRecommended({super.key, this.cubit});

  final CollectionCubit? cubit;

  @override
  State<CartRecommended> createState() => _CartRecommendedState();
}

class _CartRecommendedState extends State<CartRecommended> {
  late final CollectionCubit _cubit;
  late final bool _ownsCubit;

  @override
  void initState() {
    super.initState();
    _ownsCubit = widget.cubit == null;
    _cubit = widget.cubit ?? CollectionCubit();
    if (_ownsCubit) {
      _cubit.getCollection(slug: 'new', sort: 'popular');
    }
  }

  @override
  void dispose() {
    if (_ownsCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<CollectionCubit, CollectionState>(
      bloc: _cubit,
      builder: (context, state) {
        if (state is CollectionGot && state.collection.products.isNotEmpty) {
          final products = state.collection.products;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  l10n.recommended,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 342,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: products.length > 8 ? 8 : products.length,
                  itemBuilder: (context, index) {
                    if (index >= products.length) return const SizedBox.shrink();
                    return SizedBox(
                      width: 180,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ProductCard(product: products[index]),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
