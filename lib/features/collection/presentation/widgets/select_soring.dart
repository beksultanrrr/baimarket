import 'package:flutter/material.dart';

import '../../../../core/widgets/sort_sheet.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/collection_cubit.dart';

/// Пункты сортировки коллекции. Без `discount`: в отличие от розыгрышей,
/// ручка `model/by-collection/:slug` этот слаг не обещает — добавлять только
/// после проверки бэка.
List<String> sorting = ['popular', 'cheap', 'expensive'];

String collectionSortLabel(AppLocalizations l10n, String sort) {
  switch (sort) {
    case 'cheap':
      return l10n.sortCheap;
    case 'expensive':
      return l10n.sortExpensive;
    case 'popular':
    default:
      return l10n.sortPopular;
  }
}

/// Открывает общий шит сортировки и применяет выбор к [cubit].
///
/// [controller] держит подпись текущей сортировки — её показывает кнопка над
/// списком товаров.
Future<void> showSortingSelectionModal(
  BuildContext context,
  TextEditingController controller,
  String slug,
  CollectionCubit cubit,
) async {
  final l10n = AppLocalizations.of(context)!;

  // Текущий выбор восстанавливаем из подписи в контроллере: слаг отдельно
  // нигде не хранится.
  final current = sorting.firstWhere(
    (option) => collectionSortLabel(l10n, option) == controller.text,
    orElse: () => sorting.first,
  );

  final picked = await showSortSheet(
    context: context,
    current: current,
    options: sorting,
    labelOf: collectionSortLabel,
  );
  if (picked == null) return;

  controller.text = collectionSortLabel(l10n, picked);
  cubit.getCollection(slug: slug, sort: picked);
}
