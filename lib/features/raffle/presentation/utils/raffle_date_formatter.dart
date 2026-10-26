import 'package:flutter/material.dart';

import '../../../../core/utils/app_date_formatter.dart';

/// Тонкий делегат над [AppDateFormatter] — таблицы месяцев переехали в core,
/// чтобы их могли использовать отзывы и витрины магазинов. Сигнатуры и вывод
/// не менялись, поэтому call-sites розыгрышей трогать не нужно.
class RaffleDateFormatter {
  const RaffleDateFormatter._();

  /// Formats an ISO date string as "21 март (19:00)" in the current locale.
  static String formatDrawDate({
    required BuildContext context,
    required String? iso,
  }) =>
      AppDateFormatter.formatDrawDate(context: context, iso: iso);

  /// Formats an ISO date string as "21 марта" in the current locale.
  static String formatDayMonth({
    required BuildContext context,
    required String? iso,
  }) =>
      AppDateFormatter.formatDayMonth(context: context, iso: iso);
}
