import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_pallete.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../core/widgets/load_more_listener.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../cubit/seller_store_cubit.dart';
import '../widgets/seller_products_section.dart';
import '../widgets/seller_store_header.dart';
import '../../../live/presentation/widgets/live_shopping_scope.dart';

/// Витрина одного магазина — `GET /seller/:id/models`.
///
/// [titleOverride] прилетает через `extra` от того, кто уже знает имя магазина
/// (карточка на «Все магазины», шеврон продавца на детали товара). При холодном
/// старте по прямой ссылке его нет, и кубит достаёт продавца из `GET /seller`.
class SellerStorePage extends StatefulWidget {
  const SellerStorePage({super.key, required this.id, this.titleOverride});

  final int id;
  final String? titleOverride;

  @override
  State<SellerStorePage> createState() => _SellerStorePageState();
}

class _SellerStorePageState extends State<SellerStorePage> {
  late final SellerStoreCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SellerStoreCubit();
    // Имя уже знаем — второй запрос за списком продавцов не нужен.
    _cubit.load(id: widget.id, needSeller: widget.titleOverride == null);
    // Состояние кнопок «Купить» / «В корзине» на карточках берётся из
    // CartCubit, а не из `cartQuantity` в ответе — подтягиваем корзину.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CartCubit>().getCart();
    });
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: mainColorLight,
        body: BlocBuilder<SellerStoreCubit, SellerStoreState>(
          builder: (context, state) {
            if (state.status == SellerStoreStatus.notFound) {
              return _MessageView(message: AppLocalizations.of(context)!.sellerNotFound);
            }
            if (state.status == SellerStoreStatus.error && state.models.isEmpty) {
              return _MessageView(
                message: AppLocalizations.of(context)!.sellersLoadError,
                onRetry: () => _cubit.load(id: widget.id, sort: state.sort),
              );
            }

            final title = widget.titleOverride ?? (state.seller?.displayNameTwoLines.isNotEmpty == true ? state.seller!.displayNameTwoLines : AppLocalizations.of(context)!.sellerStoreTitleFallback);

            final productsSection = SellerProductsSection(
              models: state.models,
              total: state.total,
              sort: state.sort,
              status: state.status,
              onSortChanged: (sort) => _cubit.changeSort(id: widget.id, sort: sort),
            );

            return Stack(
              children: [
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(heightFactor: 0.5, widthFactor: 1, child: ColoredBox(color: Colors.white)),
                ),
                AppRefreshIndicator(
                  onRefresh: () => _cubit.refresh(id: widget.id),
                  dark: true,
                  child: LoadMoreListener(
                    hasMore: state.hasMore,
                    onLoadMore: () => _cubit.loadMore(id: widget.id),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      slivers: [
                        SliverToBoxAdapter(
                          child: SellerStoreHeader(title: title, avatarUrl: state.seller?.avatarUrl, description: state.seller?.description),
                        ),
                        // У магазина без товаров белый блок тянем до низа
                        // экрана, иначе под ним видно зелёный фон Scaffold.
                        // fillOverscroll — чтобы блок не отрывался от низа на
                        // bouncing-свайпе; остаток добирает белая подложка выше.
                        if (productsSection.fillsViewport) SliverFillRemaining(hasScrollBody: false, fillOverscroll: true, child: productsSection) else SliverToBoxAdapter(child: productsSection),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Gilroy', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        liveAwareDismiss(context);
                      }
                    },
                    child: Text(l10n.goToShopping, style: const TextStyle(color: Colors.white)),
                  ),
                  if (onRetry != null)
                    TextButton(
                      onPressed: onRetry,
                      child: Text(l10n.tryAgain, style: const TextStyle(color: Colors.white)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
