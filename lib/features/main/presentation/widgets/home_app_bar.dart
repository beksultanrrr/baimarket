import 'package:bai_market/core/auth/sign_out.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 2, left: 20, right: 20, bottom: 8),
      child: Row(
        children: [
          SvgPicture.asset('assets/icons/main_page/main_page_logo.svg'),
          const Spacer(),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              context.push('/notification');
            },
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
