import 'package:bai_market/core/app_pallete.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/translation_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/product_model.dart';

class ProductTags extends StatelessWidget {
  const ProductTags({super.key, required this.model});
  final ProductModel model;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tags = <_TagData>[];

    // Add collection-based tags
    if (model.collections != null) {
      for (final col in model.collections!) {
        final name = TranslationUtils.getLocalizedDescription(
          context: context,
          descriptionKz: col.nameKz ?? col.name ?? '',
          descriptionRu: col.nameRu ?? col.name ?? '',
          descriptionEn: col.nameEn ?? col.name ?? '',
        );
        if (name.isNotEmpty) {
          tags.add(_TagData(name, darkButtonColor, Colors.white));
        }
      }
    }

    // Add "New" tag if deal is true
    if (model.deal == true) {
      tags.add(_TagData(l10n.newTag, accentSoftPink, darkButtonColor));
    }

    // Add discount tag
    if (model.oldPrice != null && model.price != null && model.oldPrice! > model.price!) {
      final discount = ((1 - model.price! / model.oldPrice!) * 100).round();
      tags.add(
        _TagData('${l10n.discount} -$discount%', accentSoftGreen, darkButtonColor),
      );
    }

    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags.map((tag) => _TagChip(tag: tag)).toList(),
    );
  }
}

class _TagData {
  final String label;
  final Color background;
  final Color foreground;
  _TagData(this.label, this.background, this.foreground);
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});
  final _TagData tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: tag.background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        tag.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: tag.foreground,
          fontFamily: 'Gilroy',
        ),
      ),
    );
  }
}
