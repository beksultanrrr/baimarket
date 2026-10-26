import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/app_pallete.dart';
import '../../../../core/urls.dart';
import '../../../../core/widgets/show_image.dart';

class PhotoAvatarTile extends StatelessWidget {
  const PhotoAvatarTile({
    super.key,
    required this.imageUrl,
    this.localImage,
    this.isUploading = false,
    this.onTap,
  });

  final String imageUrl;
  final File? localImage;
  final bool isUploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        // Макет: 80×80, скругление 15, заливка #000000 3% и тонкая рамка.
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          color: fieldFill,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: hairlineBorder, width: kHairlineWidth),
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (isUploading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (localImage != null) {
      return Image.file(localImage!, fit: BoxFit.cover);
    }
    if (imageUrl.isNotEmpty) {
      return NetworkImageWidget(url: '$imgUrl$imageUrl');
    }
    return Center(
      child: SvgPicture.asset(
        'assets/icons/gallery.svg',
        height: 24,
        width: 24,
      ),
    );
  }
}
