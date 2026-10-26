import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/urls.dart';
import '../../../../core/utils/app_date_formatter.dart';
import '../../../../core/widgets/shimmer.dart';
import '../../../../core/widgets/show_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/seller_model.dart';
import '../cubit/seller_list_cubit.dart';
import '../../../live/presentation/widgets/live_shopping_scope.dart';

/// Вкладка «Все магазины»: стопка карточек по `GET /seller`.
///
/// Заменяет `core/widgets/shop_banners.dart` с тремя захардкоженными PNG.
/// Фон карточки — `bannerUrl` целиком (готовая плашка с градиентом и фото,
/// отдельных полей под цвет/фото в контракте нет), заголовок и подпись
/// рисуются поверх из `firstName`/`lastName`/`description`.
class SellerBanners extends StatelessWidget {
  const SellerBanners({super.key, this.padding = EdgeInsets.zero});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<SellerListCubit, SellerListState>(
      builder: (context, state) {
        final Widget body;
        switch (state.status) {
          case SellerListStatus.initial:
          case SellerListStatus.loading:
            body = const _Skeleton();
          case SellerListStatus.error:
            body = _Message(
              message: l10n.sellersLoadError,
              actionLabel: l10n.tryAgain,
              onAction: () => context.read<SellerListCubit>().load(),
            );
          case SellerListStatus.loaded:
            body = state.sellers.isEmpty
                ? _Message(message: l10n.sellersEmpty)
                : Column(
                    children: [
                      for (int i = 0; i < state.sellers.length; i++) ...[
                        if (i != 0) const SizedBox(height: 12),
                        _SellerBannerCard(seller: state.sellers[i]),
                      ],
                    ],
                  );
        }
        return Padding(padding: padding, child: body);
      },
    );
  }
}

class _SellerBannerCard extends StatelessWidget {
  const _SellerBannerCard({required this.seller});

  final SellerModel seller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = seller.displayNameTwoLines;
    final description = seller.description?.trim() ?? '';
    final raffleEnd = seller.raffle?.endDate;
    final raffleDate =
        AppDateFormatter.formatDayMonth(context: context, iso: raffleEnd);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => liveAwarePush(
        context,
        '/seller/${seller.id}',
        extra: {'title': seller.displayName},
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 136,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // solidFallback: дефолтная заглушка NetworkImageWidget — фото
              // косметики, для баннера магазина она смотрелась бы неуместно.
              NetworkImageWidget(
                url: '$imgUrl${seller.bannerUrl ?? ''}',
                fit: BoxFit.cover,
                solidFallback: true,
                fallbackColor: const Color(0xFF1E1E1E),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (raffleDate.isNotEmpty) ...[
                      _DateChip(label: l10n.sellerRaffleDate(raffleDate)),
                      const Spacer(),
                    ],
                    if (title.isNotEmpty)
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        SizedBox(height: 136, child: SimpleShimmer(borderRadius: 16)),
        SizedBox(height: 12),
        SizedBox(height: 136, child: SimpleShimmer(borderRadius: 16)),
        SizedBox(height: 12),
        SizedBox(height: 136, child: SimpleShimmer(borderRadius: 16)),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            if (actionLabel != null && onAction != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
      ),
    );
  }
}
