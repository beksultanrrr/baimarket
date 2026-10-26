import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../cart/data/models/cart_item_model.dart';
import '../../../cart/data/models/cart_model.dart';
import 'section_card.dart';
import 'total_price_block.dart' show calculateTotalDiscount;

class OrderTotalSection extends StatelessWidget {
  const OrderTotalSection({
    super.key,
    required this.cartModel,
    required this.deliveryPrice,
    this.deliveryStatusText,
  });

  final CartModel cartModel;

  /// Цена доставки из котировки. `null` — расчёта ещё нет: в строке доставки
  /// показываем [deliveryStatusText], а в итог доставку не кладём.
  final int? deliveryPrice;

  /// Что писать вместо цены, пока её нет («введите индекс», «рассчитываем…»,
  /// ошибка расчёта).
  final String? deliveryStatusText;

  @override
  Widget build(BuildContext context) {
    final items = cartModel.cartItems ?? const <CartItemModel>[];

    // Сумма товаров берётся С СЕРВЕРА (`CartModel.totalPrice`), а не считается
    // локально. Бэк спишет ровно `order.totalPrice + order.deliveryPrice`, где
    // totalPrice — это и есть серверный итог по товарам. Локальный fold по
    // `oldPrice ?? price` давал другое число (oldPrice — цена ДО скидки, а на
    // части позиций она вообще ниже актуальной), и пользователь видел на
    // чекауте не ту сумму, которая спишется. Не «оптимизировать» обратно.
    final serverGoods = cartModel.totalPrice;

    // Фолбэк: сервер итог не прислал — экран ронять нельзя, считаем как раньше.
    final goods =
        serverGoods ?? (_goodsBeforeDiscount(items) - calculateTotalDiscount(items));

    // Сумма до скидок берётся из ТОГО ЖЕ источника, что и `goods`. Смешивать
    // серверный итог с локальным fold нельзя: именно так рядом оказывались две
    // величины, посчитанные по разным основаниям.
    final goodsBeforeDiscount =
        serverGoods != null ? cartModel.oldTotalPrice : _goodsBeforeDiscount(items);

    // Скидка — информационная величина: она уже учтена сервером в `goods`
    // и в итог «К оплате» НЕ входит.
    final discount = (goodsBeforeDiscount != null && goodsBeforeDiscount > goods)
        ? goodsBeforeDiscount - goods
        : 0;
    final hasDiscount = discount > 0;

    final delivery = deliveryPrice ?? 0;

    // К оплате = серверные товары + доставка. Ровно эту сумму спишет бэк.
    final totalAfter = goods + delivery;

    // Зачёркнутая цена допустима только на той же базе, что и итог:
    // «товары до скидок + доставка». Нет серверной суммы до скидок —
    // зачёркивать нечего.
    final totalBefore = hasDiscount ? goodsBeforeDiscount! + delivery : null;

    final l10n = AppLocalizations.of(context)!;

    return SectionCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.totalAmount,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _line(label: l10n.items, value: _formatTenge(goods)),
          const SizedBox(height: 10),
          _line(
            label: l10n.discount,
            value: hasDiscount ? '-${_formatTenge(discount)}' : '0₸',
            valueColor: hasDiscount ? const Color(0xFFFF3B47) : Colors.black,
          ),
          const SizedBox(height: 10),
          _line(
            label: l10n.delivery,
            value: deliveryPrice != null ? _formatTenge(deliveryPrice!) : (deliveryStatusText ?? ''),
            valueColor: deliveryPrice != null ? Colors.black : const Color(0xFF8A8A8A),
            valueIsHint: deliveryPrice == null,
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEDEDED)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                l10n.amountToPay,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              if (totalBefore != null) ...[
                Text(
                  _formatTenge(totalBefore),
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9A9A9A),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                _formatTenge(totalAfter),
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          if (hasDiscount) ...[
            const SizedBox(height: 12),
            _SavedPill(amount: discount),
          ],
        ],
      ),
    );
  }

  Widget _line({
    required String label,
    required String value,
    Color valueColor = Colors.black,
    bool valueIsHint = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 12),
        // Вместо цены доставки тут может стоять целая фраза-подсказка,
        // поэтому значение переносится, а не вылезает за карточку.
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontFamily: 'Gilroy',
              // Подсказка вместо цены — фраза на пару строк, набирать её
              // цифровым весом не надо.
              fontSize: valueIsHint ? 13 : 16,
              fontWeight: valueIsHint ? FontWeight.w500 : FontWeight.w700,
              color: valueColor,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  /// Локальный подсчёт суммы товаров до скидок. Используется ТОЛЬКО как
  /// фолбэк, когда сервер не прислал `CartModel.totalPrice`: на реальных
  /// данных он расходится с серверным итогом.
  int _goodsBeforeDiscount(List<CartItemModel> items) {
    int sum = 0;
    for (final item in items) {
      final model = item.model;
      if (model == null) continue;
      final unit = model.oldPrice ?? model.price ?? 0;
      sum += unit * item.quantity;
    }
    return sum;
  }
}

class _SavedPill extends StatelessWidget {
  const _SavedPill({required this.amount});
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F0FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/main_plus.svg',
            height: 28,
            width: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.youSaved,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2F66),
              ),
            ),
          ),
          Text(
            _formatTenge(amount),
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2F66),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTenge(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  int count = 0;
  for (int i = s.length - 1; i >= 0; i--) {
    buf.write(s[i]);
    count++;
    if (count == 3 && i != 0) {
      buf.write(' ');
      count = 0;
    }
  }
  final reversed = buf.toString().split('').reversed.join();
  return '$reversed₸';
}
