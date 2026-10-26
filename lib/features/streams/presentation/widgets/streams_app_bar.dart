import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';

class StreamsAppBar extends StatelessWidget {
  const StreamsAppBar({super.key, this.onSearch});
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: SizedBox(
        height: 30,
        child: Row(
          children: [
            Text(
              l10n.streams,
              style: const TextStyle(fontFamily: 'Gilroy', fontSize: 24, fontWeight: FontWeight.w500, color: Colors.white, letterSpacing: 0.48, height: 1.0),
            ),
            const Spacer(),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(30, 30),
              onPressed: onSearch ?? () => context.push('/search'),
              child: SvgPicture.asset('assets/icons/stream/search.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
            ),
            // const SizedBox(width: 20),
            // Plus-кнопка как на главной — тот же SVG, тот же роут.
            // CupertinoButton(
            //   padding: EdgeInsets.zero,
            //   minimumSize: const Size(30, 30),
            //   onPressed: () => context.push('/plus'),
            //   child: SvgPicture.asset('assets/icons/main_page/main_page_plus_icon.svg', height: 30),
            // ),
          ],
        ),
      ),
    );
  }
}
