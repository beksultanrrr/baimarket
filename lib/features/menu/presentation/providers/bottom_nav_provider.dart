import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Индекс выбранного таба нижней навигации.
///
/// Раньше провайдер создавался **на каждый инстанс** `MenuPage` прямо в
/// `initState`, из-за чего снаружи было не узнать, открыт ли сейчас таб
/// корзины. Плашке корзины это нужно, чтобы не показываться поверх самой
/// корзины. Прецедент такого же вынесенного провайдера —
/// `catalogTopTabProvider` в `catalog_top_switcher.dart`.
final bottomNavIndexProvider = StateProvider<int>((_) => 0);

const kMenuTabHome = 0;
const kMenuTabStreams = 1;
const kMenuTabCatalog = 2;
const kMenuTabCart = 3;
const kMenuTabProfile = 4;

int menuTabIndexFor(String page) => switch (page) {
      'home' => kMenuTabHome,
      'streams' => kMenuTabStreams,
      'catalog' => kMenuTabCatalog,
      'cart' => kMenuTabCart,
      'profile' => kMenuTabProfile,
      _ => kMenuTabHome,
    };
