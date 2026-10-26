import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../core/app_pallete.dart';
import 'base_avatar_tile.dart';
import 'photo_avatar_tile.dart';

class AvatarSelectorSection extends StatelessWidget {
  const AvatarSelectorSection({
    super.key,
    required this.initial,
    required this.imageUrl,
    required this.baseLabel,
    required this.selectLabel,
    required this.onPickPhoto,
    this.localImage,
    this.isUploading = false,
  });

  final String initial;
  final String imageUrl;
  final String baseLabel;
  final String selectLabel;
  final VoidCallback onPickPhoto;
  final File? localImage;
  final bool isUploading;

  bool get _hasCustomPhoto => localImage != null || imageUrl.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AvatarColumn(
          label: baseLabel,
          child: BaseAvatarTile(initial: initial, selected: !_hasCustomPhoto),
        ),
        const SizedBox(width: 25),
        // В макете разделитель пунктирный и идёт во всю высоту плиток.
        const Padding(
          padding: EdgeInsets.only(top: 21),
          child: SizedBox(
            height: 80,
            width: kHairlineWidth,
            child: CustomPaint(painter: _DashedVerticalPainter()),
          ),
        ),
        const SizedBox(width: 25),
        _AvatarColumn(
          label: selectLabel,
          child: PhotoAvatarTile(imageUrl: imageUrl, localImage: localImage, isUploading: isUploading, onTap: onPickPhoto),
        ),
      ],
    );
  }
}

/// Вертикальный пунктир между плитками аватара — штрих 3, пропуск 3,
/// цвет #000000 при 7%, как в макете.
class _DashedVerticalPainter extends CustomPainter {
  const _DashedVerticalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 3.0;
    const gap = 3.0;
    final paint = Paint()
      ..color = hairlineBorder
      ..strokeWidth = kHairlineWidth;

    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dash), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedVerticalPainter oldDelegate) => false;
}

class _AvatarColumn extends StatelessWidget {
  const _AvatarColumn({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'Gilroy', fontSize: 14, fontWeight: FontWeight.w400, color: Colors.black),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
