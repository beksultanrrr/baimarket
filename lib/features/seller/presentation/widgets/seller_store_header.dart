import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_pallete.dart';
import '../../../../core/urls.dart';
import '../../../../core/widgets/show_image.dart';
import '../../../live/presentation/widgets/live_shopping_scope.dart';

/// Шапка витрины магазина: кнопка назад, аватар и название.
///
/// Дизайн портирован из `catalog/presentation/pages/shop_page.dart` (`_Header`),
/// который был мёртвым кодом и удаляется вместе с маршрутом `/shop`.
class SellerStoreHeader extends StatelessWidget {
  const SellerStoreHeader({
    super.key,
    required this.title,
    this.avatarUrl,
    this.description,
  });

  final String title;
  final String? avatarUrl;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    final hasDescription =
        description != null && description!.trim().isNotEmpty;

    return Container(
      color: mainColorLight,
      padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BackButton(),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (hasAvatar) ...[
                ClipOval(
                  child: SizedBox(
                    height: 56,
                    width: 56,
                    child: NetworkImageWidget(
                      url: '$imgUrl$avatarUrl',
                      fit: BoxFit.cover,
                      solidFallback: true,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF5DDD3),
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
          if (hasDescription) ...[
            const SizedBox(height: 10),
            Text(
              description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          liveAwareDismiss(context);
        }
      },
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/icons/arrow_left.svg',
            height: 20,
            width: 20,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
