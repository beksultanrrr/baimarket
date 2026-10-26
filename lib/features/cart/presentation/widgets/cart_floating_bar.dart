import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/app_pallete.dart';
import '../../../../core/ui/bottom_bar_metrics.dart';
import '../../../../core/urls.dart';
import '../../../../core/widgets/show_image.dart';
import '../../../../l10n/app_localizations.dart';

/// Плашка корзины: миниатюры, количество, сумма и кнопка оформления.
///
/// «Глупый» виджет — вся логика видимости и переходов в [CartFloatingBarHost].
/// Материала выше по дереву нет (виджет живёт в `MaterialApp.builder`), поэтому
/// никаких `InkWell` — только `GestureDetector` и `CupertinoButton`.
class CartFloatingBar extends StatelessWidget {
  const CartFloatingBar({
    super.key,
    required this.itemsCount,
    required this.totalPrice,
    required this.thumbnails,
    required this.busy,
    required this.onOpenCart,
    required this.onCheckout,
  });

  final int itemsCount;
  final int totalPrice;

  /// Имена файлов фото. Больше [maxThumbnails] не рисуем — остальные
  /// схлопываются в «+N», иначе миниатюры съедают ширину у счётчика и цены.
  final List<String> thumbnails;

  static const maxThumbnails = 2;

  /// Летит мутация корзины — оформление временно заблокировано.
  final bool busy;

  final VoidCallback onOpenCart;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shown = thumbnails.take(maxThumbnails).toList();
    final extra = itemsCount - shown.length;

    // Прозрачный Material обязателен: виджет живёт в `MaterialApp.builder`,
    // где Material выше по дереву нет, и Flutter рисует Text отладочным
    // стилем — с жёлтым двойным подчёркиванием.
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: onOpenCart,
        child: Container(
          height: kCartFloatingBarHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _Thumbnails(urls: shown, extra: extra > 0 ? extra : 0),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // maxLines обязателен: в плашке высотой 64 две строки уже не
                  // помещаются, а «12 товаров» на узком экране легко переносится.
                  Text(
                    l10n.cartItemsCount(itemsCount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  busy
                      ? const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: CupertinoActivityIndicator(radius: 8),
                        )
                      : Text(
                          l10n.price(totalPrice.toString()),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            height: 1.2,
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Короткая подпись: «Перейти к оформлению» съедала ширину и
            // выдавливала счётчик товаров на вторую строку.
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(0, 40),
              borderRadius: BorderRadius.circular(14),
              color: mainColorDark,
              onPressed: busy ? null : onCheckout,
              child: Text(
                l10n.checkoutShort,
                maxLines: 1,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnails extends StatelessWidget {
  const _Thumbnails({required this.urls, required this.extra});

  final List<String> urls;
  final int extra;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    const size = 40.0;
    const step = 26.0;
    final width = size + step * (urls.length - 1) + (extra > 0 ? step : 0);

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: [
          for (int i = 0; i < urls.length; i++)
            Positioned(
              left: i * step,
              child: Container(
                height: size,
                width: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: NetworkImageWidget(
                    url: '$imgUrl${urls[i]}',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: urls.length * step,
              child: Container(
                height: size,
                width: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF0F0F0),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  '+$extra',
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
