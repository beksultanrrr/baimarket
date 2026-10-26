import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/user_city_storage.dart';

class CatalogAppBar extends StatefulWidget {
  const CatalogAppBar({super.key});

  @override
  State<CatalogAppBar> createState() => _CatalogAppBarState();
}

class _CatalogAppBarState extends State<CatalogAppBar> with WidgetsBindingObserver {
  String _city = 'Алматы';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCity();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadCity();
    }
  }

  Future<void> _loadCity() async {
    final name = await getUserCity();
    if (!mounted) return;
    if (name != _city) setState(() => _city = name);
  }

  Future<void> _openAddresses() async {
    await context.push('/my_address');
    if (!mounted) return;
    await _loadCity();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Figma frame 16271: header сидит на y=70 от верха экрана
      // (статусбар iPhone 15 = 47), внизу до табов остаётся ~23px.
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 23, left: 20, right: 20, bottom: 23),
      child: Row(
        children: [
          // Location
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _openAddresses,
            child: Row(
              children: [
                SvgPicture.asset('assets/icons/location.svg', height: 24, width: 24),
                const SizedBox(width: 6),
                Text(
                  _city,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black, fontFamily: 'Gilroy'),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: Colors.black54),
              ],
            ),
          ),
          const Spacer(),
          // CupertinoButton(padding: EdgeInsets.zero, onPressed: () => context.push('/plus'), child: SvgPicture.asset('assets/icons/main_page/main_page_plus_icon.svg', height: 30)),
          const SizedBox(width: 10),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => context.push('/notification'),
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.05), shape: BoxShape.circle),
              child: Center(child: SvgPicture.asset('assets/icons/main_page/main_page_chat.svg', height: 24, width: 24)),
            ),
          ),
        ],
      ),
    );
  }
}
