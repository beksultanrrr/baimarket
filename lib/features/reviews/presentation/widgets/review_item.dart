import 'package:bai_market/core/app_pallete.dart';
import 'package:flutter/material.dart';

import '../../../../core/urls.dart';
import '../../../../core/utils/app_date_formatter.dart';
import '../../../../core/widgets/show_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/review_model.dart';

/// Один отзыв. Вёрстка перенесена без изменений из
/// `product/presentation/widgets/review_item.dart`, который работал на
/// захардкоженном `MockReview`.
///
/// Производные значения (инициалы, подпись автора, дата) считаются здесь:
/// в ответе бэка их нет, есть только `firstName`, `lastNameInitial`,
/// `avatarUrl` и ISO-дата.
class ReviewItem extends StatelessWidget {
  const ReviewItem({
    super.key,
    required this.review,
    this.showDivider = false,
    this.maxLines,
  });

  final ReviewModel review;
  final bool showDivider;

  /// В превью-блоке на детали товара ограничиваем, чтобы один длинный отзыв
  /// не разорвал карточку. На отдельном экране — полный текст.
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final firstName = review.user?.firstName?.trim() ?? '';
    final initial = review.user?.lastNameInitial?.trim() ?? '';
    // «Асылбек Д». Имени может не быть — у пользователя нет профиля.
    final name = firstName.isEmpty
        ? l10n.reviewAnonymous
        : [firstName, initial].where((s) => s.isNotEmpty).join(' ');

    final initials = _initials(firstName, initial);
    final date = AppDateFormatter.formatDayMonthYear(
      context: context,
      iso: review.createdAt,
    );
    final avatarUrl = review.user?.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDivider)
          Divider(
            color: Colors.black.withAlpha(15),
            height: 1,
            thickness: 1,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasAvatar)
                    ClipOval(
                      child: SizedBox(
                        height: 30,
                        width: 30,
                        child: NetworkImageWidget(
                          url: '$imgUrl$avatarUrl',
                          fit: BoxFit.cover,
                          solidFallback: true,
                        ),
                      ),
                    )
                  else
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: mainColorLight,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                        if (date.isNotEmpty)
                          Text(
                            date,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                              fontFamily: 'Gilroy',
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                review.text ?? '',
                maxLines: maxLines,
                overflow: maxLines == null ? null : TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  fontFamily: 'Gilroy',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _initials(String firstName, String lastNameInitial) {
    final a = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final b = lastNameInitial.isNotEmpty ? lastNameInitial[0].toUpperCase() : '';
    final joined = '$a$b';
    return joined.isEmpty ? '?' : joined;
  }
}
