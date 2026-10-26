import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../cubit/notification_cubit.dart';

class _CategoryItem {
  final String slug;
  final String title;
  final String iconPath;
  final Color bgColor;
  final Color iconColor;

  const _CategoryItem({
    required this.slug,
    required this.title,
    required this.iconPath,
    required this.bgColor,
    required this.iconColor,
  });
}

List<_CategoryItem> _buildCategories(AppLocalizations l10n) => [
  _CategoryItem(
    slug: 'purchase',
    title: l10n.notificationCategoryPurchase,
    iconPath: 'assets/icons/notification/notification_shop.svg',
    bgColor: const Color(0xFFDFF6F2),
    iconColor: const Color(0xFF71CD32),
  ),
  _CategoryItem(
    slug: 'delivery',
    title: l10n.notificationCategoryDelivery,
    iconPath: 'assets/icons/notification/notification_delivery.svg',
    bgColor: const Color(0xFFFFE8E4),
    iconColor: const Color(0xFFE05A4B),
  ),
  _CategoryItem(
    slug: 'stream',
    title: l10n.notificationCategoryStream,
    iconPath: 'assets/icons/notification/notification_live.svg',
    bgColor: const Color(0xFFE8E6FF),
    iconColor: const Color(0xFF6B5CE7),
  ),
  _CategoryItem(
    slug: 'subscription',
    title: l10n.notificationCategorySubscription,
    iconPath: 'assets/icons/notification/notification_subscriptions.svg',
    bgColor: const Color(0xFFDCEEFF),
    iconColor: const Color(0xFF3A7BD5),
  ),
];

class NotificationList extends StatelessWidget {
  const NotificationList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationCubit()..getNotifications(),
      child: const _NotificationListContent(),
    );
  }
}

class _NotificationListContent extends StatelessWidget {
  const _NotificationListContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = _buildCategories(l10n);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5F5F5),
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: SvgPicture.asset(
            'assets/icons/arrow_left.svg',
            width: 24,
            height: 24,
          ),
        ),
        title: Text(
          l10n.notifications,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.black,
            fontFamily: 'Gilroy',
            height: 1.0,
            letterSpacing: 0,
          ),
        ),
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          final unreadCounts = <String, int>{};
          if (state is NotificationGot) {
            for (final n in state.notifications) {
              if (!n.read) {
                final key = n.type ?? '';
                unreadCounts[key] = (unreadCounts[key] ?? 0) + 1;
              }
            }
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final count = unreadCounts[cat.slug] ?? 0;
              return _CategoryCard(
                category: cat,
                unreadCount: count,
                onTap: () => context.push('/notification/${cat.slug}'),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.unreadCount,
    required this.onTap,
  });

  final _CategoryItem category;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: category.bgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  category.iconPath,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    category.iconColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                category.title,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  height: 1.0,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (unreadCount > 0)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
