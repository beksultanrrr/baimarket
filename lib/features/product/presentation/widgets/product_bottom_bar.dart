import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/auth/auth_gate.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../live/presentation/widgets/live_shopping_scope.dart';
import '../../data/models/product_model.dart';

class ProductBottomBar extends StatelessWidget {
  const ProductBottomBar({super.key, required this.model});
  final ProductModel model;

  static const _teal = Color(0xFF71CD32);
  static const _radius = BorderRadius.all(Radius.circular(15));

  Future<void> _addToCart(BuildContext context) async {
    final cartCubit = context.read<CartCubit>();
    final ok = await ensureAuthenticated(context, pendingAction: () => cartCubit.addCart(id: model.id, product: model));
    if (!ok) return;
    cartCubit.addCart(id: model.id, product: model);
  }

  @override
  Widget build(BuildContext context) {
    if (model.inStockCount != null && model.inStockCount! <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 32),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))]),
      child: BlocBuilder<CartCubit, CartState>(
        buildWhen: (prev, next) {
          int qty(CartState s) => s is CartGot ? (s.cart.cartItems?.where((i) => i.model?.id == model.id).firstOrNull?.quantity ?? 0) : 0;
          return qty(prev) != qty(next);
        },
        builder: (context, _) {
          final cubit = context.read<CartCubit>();
          final count = cubit.quantityOf(model.id);

          final child =
              count > 0
                  ? _InCartRow(
                    key: const ValueKey('in-cart'),
                    count: count,
                    unitPrice: model.price ?? 0,
                    onRemove: () => cubit.removeCart(id: model.id),
                    onAdd: () => _addToCart(context),
                    onGoToCart: () {
                      liveAwarePush(context, '/cart');
                    },
                  )
                  : _BuyRow(key: const ValueKey('buy'), price: model.price ?? 0, oldPrice: model.oldPrice, onBuy: () => _addToCart(context));

          return AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: child);
        },
      ),
    );
  }
}

// ── State: 0 items ──────────────────────────────────────────────────────────

class _BuyRow extends StatelessWidget {
  const _BuyRow({super.key, required this.price, required this.oldPrice, required this.onBuy});
  final int price;
  final int? oldPrice;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.price(price.toString()), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black, fontFamily: GoogleFonts.inter().fontFamily)),
            if (oldPrice != null)
              Text(l10n.oldPrice(oldPrice.toString()), style: TextStyle(fontSize: 13, color: Colors.grey.shade500, decoration: TextDecoration.lineThrough, fontFamily: GoogleFonts.inter().fontFamily)),
          ],
        ),
        const Spacer(),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onBuy,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 10),
            decoration: const BoxDecoration(color: ProductBottomBar._teal, borderRadius: ProductBottomBar._radius),
            child: Text(l10n.buy, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF00520B), fontFamily: 'Gilroy')),
          ),
        ),
      ],
    );
  }
}

// ── State: ≥1 items ─────────────────────────────────────────────────────────

class _InCartRow extends StatelessWidget {
  const _InCartRow({super.key, required this.count, required this.unitPrice, required this.onRemove, required this.onAdd, required this.onGoToCart});
  final int count;
  final int unitPrice;
  final VoidCallback onRemove;
  final VoidCallback onAdd;
  final VoidCallback onGoToCart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = l10n.price((count * unitPrice).toString());
    return Row(
      children: [
        // Counter pill: [— count × price +]
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(24)),
            child: Row(
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onPressed: onRemove,
                  child: const Text('−', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Colors.black54)),
                ),
                Expanded(
                  child: Text(
                    '$count × $total',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black, fontFamily: GoogleFonts.inter().fontFamily),
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onPressed: onAdd,
                  child: const Text('+', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Colors.black54)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Go-to-cart button
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onGoToCart,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(color: ProductBottomBar._teal, borderRadius: ProductBottomBar._radius),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset('assets/icons/cart.svg', width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                const SizedBox(width: 8),
                Text(l10n.goToCart, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Gilroy')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
