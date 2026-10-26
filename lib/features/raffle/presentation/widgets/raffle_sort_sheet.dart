import 'package:flutter/material.dart';

import '../../../../core/widgets/sort_sheet.dart';
import '../../../../l10n/app_localizations.dart';

/// Keep in sync with the backend enum (see MOBILE_API_CHANGES.md).
const raffleSortOptions = <String>['popular', 'cheap', 'expensive', 'discount'];

String raffleSortLabel(AppLocalizations l10n, String sort) {
  switch (sort) {
    case 'cheap':
      return l10n.sortCheap;
    case 'expensive':
      return l10n.sortExpensive;
    case 'discount':
      return l10n.sortDiscount;
    case 'popular':
    default:
      return l10n.sortPopular;
  }
}

/// Тонкая обёртка над общим [showSortSheet] — вид шита один на всё
/// приложение, здесь задаётся только набор пунктов.
Future<String?> showRaffleSortSheet({
  required BuildContext context,
  required String current,
}) {
  return showSortSheet(
    context: context,
    current: current,
    options: raffleSortOptions,
    labelOf: raffleSortLabel,
  );
}
