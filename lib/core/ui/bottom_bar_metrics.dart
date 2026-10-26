import 'package:flutter/widgets.dart';

/// Размеры нижних панелей. До этого числа были размазаны литералами по
/// `menu_page.dart`, `cart_bottom_bar.dart` и `product_bottom_bar.dart`.

/// Высота «пилюли» нижней навигации.
const double kMenuNavBarHeight = 57;

/// Отступы вокруг неё.
const double kMenuNavBarTopPad = 4;
const double kMenuNavBarBottomPad = 8;

/// Плашка корзины.
const double kCartFloatingBarHeight = 64;
const double kCartFloatingBarGap = 8;
const double kCartFloatingBarHMargin = 16;

/// Сколько снизу занимает навигационная пилюля вместе с безопасной зоной.
double menuNavBarSpace(BuildContext context) =>
    MediaQuery.of(context).padding.bottom +
    kMenuNavBarBottomPad +
    kMenuNavBarHeight +
    kMenuNavBarTopPad;

/// На сколько поднять плашку корзины над низом экрана.
///
/// На вкладках `MenuPage` она встаёт над навигационной пилюлей, на эфире — над
/// строкой ввода комментария, на остальных экранах просто над безопасной зоной.
double cartBarBottomOffset(BuildContext context, {required String? routeName}) {
  final safeBottom = MediaQuery.of(context).padding.bottom;
  switch (routeName) {
    case '/main':
    case '/catalog':
    case '/cart':
    case '/profile':
      return menuNavBarSpace(context) + kCartFloatingBarGap;
    case '/live/:id':
    case '/live_host/:id':
      // Над полем комментария (высота 48 + отступы).
      return safeBottom + 16 + 48 + 12;
    case 'stories_viewer':
      // У сториз своего нижнего ряда нет, но плашка не должна налезать на
      // кнопку «Перейти к товару».
      return safeBottom + 16 + 48;
    default:
      return safeBottom + 12;
  }
}
