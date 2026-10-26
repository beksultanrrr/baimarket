import 'package:bai_market/core/app_pallete.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/urls.dart';
import '../../../../core/widgets/show_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';

class ProfileCartBanner extends StatelessWidget {
  const ProfileCartBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        if (state is CartGot && state.cart.cartItems != null && state.cart.cartItems!.isNotEmpty) {
          final items = state.cart.cartItems!;
          final totalPrice = items.fold<int>(0, (sum, item) => sum + (item.model?.price ?? 0) * (item.quantity));

          return Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              // Секция вокруг тоже белая, поэтому карточку выделяет рамка —
              // без неё блок сливается с фоном секции.
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: hairlineBorder, width: kHairlineWidth),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price row
                  Row(
                    children: [
                      Text(
                        '$totalPrice ₸',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: mainColorLight, fontFamily: 'Gilroy'),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF5F0E8), borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          '${items.length} ${l10n.items}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87, fontFamily: 'Gilroy'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Product images
                  SizedBox(
                    height: 68,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length > 4 ? 4 : items.length,
                      itemBuilder: (context, index) {
                        final photoUrls = items[index].model?.photoUrls;
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 68,
                          decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: photoUrls != null && photoUrls.isNotEmpty ? NetworkImageWidget(url: '$imgUrl${photoUrls[0]}', fit: BoxFit.cover) : const SizedBox.shrink(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Pay button
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => context.push('/cart'),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                        child: Center(
                          child: Text(
                            l10n.goToPayment,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Gilroy'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
