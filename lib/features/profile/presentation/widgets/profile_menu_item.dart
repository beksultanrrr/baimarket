import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileMenuItem extends StatelessWidget {
  const ProfileMenuItem({
    super.key,
    required this.svgAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = false,
    this.onLongPress,
  });

  final String svgAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  /// Скрытый вход — используется для экрана диагностики пушей.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onLongPress: onLongPress,
          child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                SvgPicture.asset(svgAsset, width: 26, height: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          fontFamily: 'Gilroy',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade400,
                          fontFamily: 'Gilroy',
                        ),
                      ),
                    ],
                  ),
                ),
                SvgPicture.asset(
                  'assets/icons/product_page/product_page_arrow_right.svg',
                  width: 20,
                  height: 20,
                ),
              ],
            ),
          ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 56,
            endIndent: 0,
            color: Colors.grey.shade200,
          ),
      ],
    );
  }
}
