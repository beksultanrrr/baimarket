import 'package:bai_market/features/cart/data/models/cart_model.dart';
import 'package:flutter/material.dart';

import '../../../cart/data/models/cart_item_model.dart';

class TotalPriceBlock extends StatelessWidget {
  const TotalPriceBlock({super.key, required this.cartModel});
  final CartModel cartModel;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Обшая сумма',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Товары',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            Text(
              '${cartModel.totalPrice}тг',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Скидка',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            Text(
              calculateTotalDiscount(cartModel.cartItems ?? []) == 0
                  ? 'Нет'
                  : '${calculateTotalDiscount(cartModel.cartItems ?? [])} тг',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Акционные номера',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            Text(
              '${countDealsInCart(cartModel.cartItems ?? [])}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Доставка',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            Text(
              'Бесплатно',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Divider(height: 1),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Итого:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            Text(
              cartModel.totalPrice.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

int countDealsInCart(List<CartItemModel> cartItems) {
  int dealCount = 0;

  for (var item in cartItems) {
    if (item.model != null &&
        item.model != null &&
        item.model!.collections != null) {
      for (var collection in item.model!.collections!) {
        if (collection.slug == 'lottery') {
          dealCount += item.quantity;
        }
      }
    }
  }

  return dealCount;
}

int calculateTotalDiscount(List<CartItemModel> cartItems) {
  int totalDiscount = 0;

  for (var item in cartItems) {
    if (item.model != null &&
        item.model!.oldPrice != null &&
        item.model!.price != null &&
        item.model!.oldPrice! > item.model!.price!) {
      int discountPerItem = item.model!.oldPrice! - item.model!.price!;
      totalDiscount += discountPerItem * item.quantity;
    }
  }

  return totalDiscount;
}
