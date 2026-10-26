import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/app_pallete.dart';
import '../../../../l10n/app_localizations.dart';

/// Шит «Добавить фото» по макету: белая панель со скруглением 30, внутри
/// заголовок и два пункта-карточки с тонкой рамкой и зелёными иконками.
class AddPhotoBottomSheet extends StatelessWidget {
  const AddPhotoBottomSheet({super.key, required this.onSourceSelected});

  final ValueChanged<ImageSource> onSourceSelected;

  static Future<void> show({required BuildContext context, required ValueChanged<ImageSource> onSourceSelected}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      // Затемнение фона в макете — #000000 при 25%.
      barrierColor: const Color(0x40000000),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) => AddPhotoBottomSheet(onSourceSelected: onSourceSelected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.addPhoto,
                  style: const TextStyle(fontFamily: 'Gilroy', fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () => Navigator.pop(context),
                  child: Container(
                    height: 24,
                    width: 24,
                    decoration: const BoxDecoration(color: Color(0xFFF0F0F0), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF8A8A8A)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _PhotoSourceTile(
              iconAsset: 'assets/icons/gallery-2.svg',
              label: l10n.gallery,
              onTap: () {
                Navigator.pop(context);
                onSourceSelected(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
            _PhotoSourceTile(
              iconAsset: 'assets/icons/camera.svg',
              label: l10n.camera,
              onTap: () {
                Navigator.pop(context);
                onSourceSelected(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoSourceTile extends StatelessWidget {
  const _PhotoSourceTile({required this.iconAsset, required this.label, required this.onTap});

  final String iconAsset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hairlineBorder, width: kHairlineWidth),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            SvgPicture.asset(iconAsset, height: 24, width: 24),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(fontFamily: 'Gilroy', fontSize: 16, fontWeight: FontWeight.w500, color: secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}
