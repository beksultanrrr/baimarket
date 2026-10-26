import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../live/presentation/widgets/live_shopping_scope.dart';

class ProductAppBar extends StatefulWidget {
  const ProductAppBar({
    super.key,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onShareTap,
  });

  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  /// Прямоугольник кнопки share в глобальных координатах — нужен на iPad,
  /// чтобы привязать поповер к самой иконке. На телефонах может быть `null`.
  final ValueChanged<Rect?> onShareTap;

  @override
  State<ProductAppBar> createState() => _ProductAppBarState();
}

class _ProductAppBarState extends State<ProductAppBar> {
  final _shareKey = GlobalKey();

  void _handleShare() {
    final box = _shareKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    widget.onShareTap(origin);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            // Карточку открывают и по внешней ссылке — тогда она единственная
            // в стеке, и голый pop() ничего бы не сделал. Внутри эфира тот же
            // вызов схлопывает шит, а не рвёт стрим.
            onPressed: () =>
                context.canPop() ? context.pop() : liveAwareDismiss(context),
            child: SvgPicture.asset(
              'assets/icons/product_page/product_page_back_arrow.svg',
              height: 26,
              width: 26,
            ),
          ),
          const Spacer(),
          CupertinoButton(
            key: _shareKey,
            padding: EdgeInsets.zero,
            onPressed: _handleShare,
            child: SvgPicture.asset(
              'assets/icons/product_page/product_page_share.svg',
              height: 26,
              width: 26,
            ),
          ),
          const SizedBox(width: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: widget.onFavoriteTap,
            child: SvgPicture.asset(
              widget.isFavorite
                  ? 'assets/icons/common/product_like_active.svg'
                  : 'assets/icons/product_page/product_page_like.svg',
              height: 26,
              width: 26,
            ),
          ),
        ],
      ),
    );
  }
}
