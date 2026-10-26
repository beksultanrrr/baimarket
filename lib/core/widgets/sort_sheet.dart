import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'choice_sheet.dart';

/// Шит сортировки «Вначале показывать».
///
/// Тонкая обёртка над общим [showChoiceSheet]: вид одинаковый со всеми
/// списками выбора в приложении, здесь задаются только пункты. Набор у
/// каждого экрана свой — он приходит в [options], подписи разворачивает
/// [labelOf].
///
/// Возвращает выбранный слаг или `null`, если шит закрыли крестиком/свайпом.
Future<String?> showSortSheet({
  required BuildContext context,
  required String current,
  required List<String> options,
  required String Function(AppLocalizations l10n, String option) labelOf,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showChoiceSheet<String>(
    context: context,
    title: l10n.showFirst,
    items: options,
    labelOf: (option) => labelOf(l10n, option),
    selected: current,
  );
}
