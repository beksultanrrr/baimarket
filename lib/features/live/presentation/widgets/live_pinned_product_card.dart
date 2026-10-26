import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/auth/auth_gate.dart';
import '../../../../core/utils/product_mappers.dart';
import '../../../../core/widgets/show_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../data/models/live_media.dart';
import '../../data/models/live_product_card_model.dart';
import 'live_shopping_scope.dart';

/// Карточка товара, который продавец показывает прямо сейчас.
///
/// Раньше здесь была лента `LiveProductStrip` поверх захардкоженной коллекции
/// `new` — к эфиру она отношения не имела. По контракту закреплённый товар
/// ровно один: `snapshot.pinnedProduct` плюс события `product:shown` /
/// `product:hidden`.
///
/// Тап по телу открывает карточку товара шитом (стрим продолжает идти), тап по
/// кнопке кладёт товар в корзину не открывая ничего: подтверждением служит
/// плашка корзины, которая и так висит поверх эфира.
class LivePinnedProductCard extends StatelessWidget {
  const LivePinnedProductCard({super.key, required this.product});

  final LiveProductCardModel product;

  Future<void> _addToCart(BuildContext context) async {
    // Захватываем всё, что зависит от context, ДО await: пока идёт проверка
    // авторизации, виджет может быть размонтирован.
    final cart = context.read<CartCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    final ok = await ensureAuthenticated(
      context,
      pendingAction: () => cart.addCart(
        id: product.id,
        product: productModelFromLive(product),
      ),
    );
    if (!ok) return;

    // Остатка в payload сокета нет, поэтому добавляем оптимистично: если товар
    // кончился, сервер откажет, CartCubit откатит позицию, а CartEventListener
    // покажет его же сообщение.
    cart.addCart(id: product.id, product: productModelFromLive(product));
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.addedToCart),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final oldPrice = product.oldPrice;
    final showOldPrice =
        oldPrice != null && product.price != null && oldPrice > product.price!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 71,
            padding: const EdgeInsets.fromLTRB(4, 3, 7, 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => openLiveProductSheet(context, product.id),
                    child: Row(
                      children: [
                        Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          clipBehavior: Clip.antiAlias,
                          alignment: Alignment.center,
                          child: NetworkImageWidget(
                            url: liveFileUrl(product.firstPhoto),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                // Описаний в форме ProductCard нет — только имя.
                                product.name ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4F4C1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${(product.price ?? 0).round()}₸',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF71CD32),
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                  if (showOldPrice) ...[
                                    const SizedBox(width: 5),
                                    Text(
                                      '${oldPrice.round()}₸',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400,
                                        color:
                                            Colors.white.withValues(alpha: 0.49),
                                        decoration: TextDecoration.lineThrough,
                                        decorationColor:
                                            Colors.white.withValues(alpha: 0.49),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _AddButton(
                  productId: product.id,
                  onAdd: () => _addToCart(context),
                  addLabel: l10n.buy,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Кнопка справа: «Купить», пока товара нет в корзине, и счётчик после.
class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.productId,
    required this.onAdd,
    required this.addLabel,
  });

  final int productId;
  final VoidCallback onAdd;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      buildWhen: (prev, next) => true,
      builder: (context, _) {
        final count = context.read<CartCubit>().quantityOf(productId);
        if (count == 0) {
          return CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(72, 32),
            onPressed: onAdd,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF71CD32),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                addLabel,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
          );
        }
        return Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF71CD32),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepButton(
                icon: Icons.remove_rounded,
                onTap: () => context.read<CartCubit>().removeCart(id: productId),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ),
              _StepButton(icon: Icons.add_rounded, onTap: onAdd),
            ],
          ),
        );
      },
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(24, 24),
      onPressed: onTap,
      child: Icon(icon, size: 16, color: Colors.white),
    );
  }
}
