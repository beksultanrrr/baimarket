import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/search'),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    SvgPicture.asset('assets/icons/main_page/main_page_search.svg', height: 24, width: 24),
                    const SizedBox(width: 12),
                    Text(
                      l10n.searchHomeHint,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0x4D000000), fontFamily: 'Gilroy'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              context.push('/favorites');
            },
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Center(child: SvgPicture.asset('assets/icons/main_page/main_page_like.svg', height: 24, width: 24)),
            ),
          ),
        ],
      ),
    );
  }
}
