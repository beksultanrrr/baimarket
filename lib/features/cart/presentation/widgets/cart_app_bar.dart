import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/app_pallete.dart';
import '../../../../l10n/app_localizations.dart';

class CartAppBar extends StatelessWidget {
  const CartAppBar({
    super.key,
    this.onClear,
    this.showClear = false,
    this.isBusy = false,
  });
  final VoidCallback? onClear;
  final bool showClear;

  /// Летит `DELETE /cart` — вместо надписи показываем индикатор, повторный тап
  /// невозможен.
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 8,
        bottom: 8,
      ),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                l10n.cart,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  fontFamily: 'Gilroy',
                ),
              ),
            ),
            if (canPop)
              Positioned(
                left: 0,
                child: CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: SvgPicture.asset(
                    'assets/icons/arrow_left.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            if (showClear)
              Positioned(
                right: 8,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: isBusy ? null : onClear,
                  child: isBusy
                      ? const CupertinoActivityIndicator(radius: 9)
                      : Text(
                          l10n.clearCart,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: mainColorLight,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
