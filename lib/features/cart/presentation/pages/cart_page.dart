import 'package:bai_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../collection/presentation/cubit/collection_cubit.dart';
import '../../../live/presentation/widgets/live_shopping_scope.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/cart_model.dart';
import '../widgets/cart_app_bar.dart';
import '../widgets/cart_bottom_bar.dart';
import '../widgets/cart_changes_banner.dart';
import '../widgets/cart_empty_state.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/cart_recommended.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key, required this.toCatalog});
  final VoidCallback? toCatalog;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CollectionCubit _recCubit = CollectionCubit();

  @override
  void initState() {
    super.initState();
    _recCubit.getCollection(slug: 'new', sort: 'popular');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CartCubit>().getCart();
    });
  }

  @override
  void dispose() {
    _recCubit.close();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<CartCubit>().getCart(),
      _recCubit.getCollection(slug: 'new', sort: 'popular'),
    ]);
  }

  /// Итог берём с сервера: `GET /cart` переписывает цены позиций на актуальные,
  /// и локальная сумма по `model.price` может разойтись с тем, что спишут при
  /// оплате. Локальный расчёт остаётся только фолбэком для оптимистично
  /// добавленной позиции, которую сервер ещё не подтвердил.
  int _calculateTotal(CartModel? cart) {
    final serverTotal = cart?.totalPrice;
    if (serverTotal != null && serverTotal > 0) return serverTotal;
    final items = cart?.cartItems ?? const <CartItemModel>[];
    return items.fold(
      0,
      (sum, item) => sum + (item.quantity * (item.model?.price ?? 0)),
    );
  }

  int _calculateSaved(CartModel? cart) {
    final total = cart?.totalPrice;
    final oldTotal = cart?.oldTotalPrice;
    if (total != null && oldTotal != null && oldTotal > total) {
      return oldTotal - total;
    }
    final items = cart?.cartItems ?? const <CartItemModel>[];
    return items.fold(0, (sum, item) {
      final old = item.model?.oldPrice ?? item.model?.price ?? 0;
      final current = item.model?.price ?? 0;
      return sum + ((old - current) * item.quantity);
    });
  }

  /// Очистка ждёт ответа сервера и держит кнопку заблокированной.
  Future<void> _onClear() async {
    await context.read<CartCubit>().clearCart();
  }

  /// Перед оформлением перечитываем корзину. Навигация — по возвращённому
  /// значению, а не по состоянию: `CartPage` смонтирована сразу в двух местах
  /// (таб и шит поверх эфира), и раньше приходилось гадать, кто из них должен
  /// уводить на оформление.
  Future<void> _onCheckout() async {
    final cart = await context.read<CartCubit>().prepareCheckout();
    if (cart == null || !mounted) return;
    liveAwarePush(context, '/make_order', extra: cart);
  }

  @override
  Widget build(BuildContext context) {
    final cartCubit = context.read<CartCubit>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<CartCubit, CartState>(
          builder: (context, state) {
            final got = state is CartGot ? state : null;
            final cart = got?.cart;
            final items = cart?.cartItems ?? const <CartItemModel>[];
            final hasItems = items.isNotEmpty;
            final busy = got?.busy ?? false;
            final busyLines = got?.busyLines ?? const <int>{};

            return Column(
              children: [
                CartAppBar(
                  showClear: hasItems,
                  // Пока летит DELETE /cart — кнопка выключена, чтобы повторный
                  // тап не отправил второй запрос.
                  onClear: busy ? null : _onClear,
                  isBusy: busy,
                ),
                if (got != null && got.changes.isNotEmpty)
                  CartChangesBanner(changes: got.changes),
                Expanded(
                  child: hasItems
                      ? _buildCartContent(cartCubit, items, busyLines)
                      : _buildEmptyContent(),
                ),
                if (hasItems)
                  CartBottomBar(
                    totalPrice: _calculateTotal(cart),
                    savedAmount: _calculateSaved(cart),
                    onCheckout: busy ? null : _onCheckout,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCartContent(
    CartCubit cartCubit,
    List<CartItemModel> items,
    Set<int> busyLines,
  ) {
    return AppRefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final item in items)
                    CartItemCard(
                      key: ValueKey(item.model?.id ?? item.id),
                      item: item,
                      isBusy: busyLines.contains(item.id),
                      onAdd: () => cartCubit.addCart(
                        id: item.model!.id,
                        product: item.model,
                      ),
                      // Последняя единица — удаляем позицию целиком одним
                      // запросом, без пары delete + повторное добавление.
                      onRemove: () => item.quantity <= 1
                          ? cartCubit.removeLine(id: item.model!.id)
                          : cartCubit.removeCart(id: item.model!.id),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            CartRecommended(cubit: _recCubit),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyContent() {
    return AppRefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CartEmptyState(onGoShopping: () => widget.toCatalog?.call()),
            const SizedBox(height: 32),
            CartRecommended(cubit: _recCubit),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
