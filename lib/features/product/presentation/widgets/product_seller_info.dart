import 'package:bai_market/core/app_pallete.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/urls.dart';
import '../../../../core/widgets/show_image.dart';
import '../../../../l10n/app_localizations.dart';

/// Карточка продавца на детали товара.
///
/// «Глупый» виджет: данные приходят снаружи из `product.seller`. Раньше сюда
/// передавалось `product.name` — то есть имя товара в качестве имени продавца,
/// плюс были захардкоженные фолбэки «Bai Market» и «4587 заказа».
class ProductSellerInfo extends StatelessWidget {
  const ProductSellerInfo({
    super.key,
    required this.name,
    this.avatarUrl,
    this.orderCount,
    this.onTap,
  });

  final String name;
  final String? avatarUrl;

  /// `null` — строку с числом заказов не показываем (лучше, чем «null заказа»).
  final int? orderCount;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (hasAvatar)
              ClipOval(
                child: SizedBox(
                  height: 40,
                  width: 40,
                  child: NetworkImageWidget(
                    url: '$imgUrl$avatarUrl',
                    fit: BoxFit.cover,
                    solidFallback: true,
                  ),
                ),
              )
            else
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFF0F0F0),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'B',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: mainColorLight,
                  ),
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                  if (orderCount != null)
                    Text(
                      l10n.sellerOrders(orderCount.toString()),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black45,
                      ),
                    ),
                ],
              ),
            ),
            SvgPicture.asset(
              'assets/icons/product_page/product_page_arrow_right.svg',
              height: 22,
              width: 22,
            ),
          ],
        ),
      ),
    );
  }
}
