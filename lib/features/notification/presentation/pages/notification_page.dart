import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../cubit/notification_cubit.dart';
import '../../data/models/notification_model.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key, required this.id});
  final String? id;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationCubit()..getNotifications(),
      child: _NotificationPageContent(categorySlug: id ?? ''),
    );
  }
}

class _NotificationPageContent extends StatelessWidget {
  const _NotificationPageContent({required this.categorySlug});
  final String categorySlug;

  String _getTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (categorySlug) {
      case 'purchase':
        return l10n.notificationCategoryPurchase;
      case 'delivery':
        return l10n.notificationCategoryDelivery;
      case 'stream':
        return l10n.notificationCategoryStream;
      case 'subscription':
        return l10n.notificationCategorySubscription;
      default:
        return l10n.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = _getTitle(context);

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
          title,
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
          if (state is NotificationGetting) {
            return const Center(child: CupertinoActivityIndicator());
          }

          if (state is NotificationGot) {
            final items = state.notifications
                .where((n) => n.type == categorySlug)
                .toList();

            if (items.isEmpty) {
              return Center(
                child: Text(
                  l10n.noNotifications,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    color: Colors.black45,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _NotificationCard(notification: items[index]),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});
  final NotificationModel notification;

  static const _structureConfig = {
    'success': (
      Color(0xFFDFF6F0),
      Color(0xFF71CD32),
      'assets/icons/notification/notification_success.svg',
    ),
    'info': (
      Color(0xFFDCEEFF),
      Color(0xFF3A7BD5),
      'assets/icons/notification/notification_info.svg',
    ),
    'error': (
      Color(0xFFFFE8E4),
      Color(0xFFE05A4B),
      'assets/icons/notification/notification_error.svg',
    ),
  };

  String _formatDate(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt);
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year;
      return '$d.$m.$y';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final struct = notification.structure?.toLowerCase() ?? 'info';
    final config = _structureConfig[struct] ?? _structureConfig['info']!;
    final bgColor = config.$1;
    final iconColor = config.$2;
    final iconPath = config.$3;

    final title = notification.title ?? '';
    final body = notification.body ?? '';
    final date = _formatDate(notification.createdAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                iconPath,
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    if (date.isNotEmpty)
                      Text(
                        date,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.black38,
                        ),
                      ),
                  ],
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
