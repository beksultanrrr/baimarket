import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../cart/data/models/cart_model.dart';
import '../../../cart/presentation/pages/cart_page.dart';
import '../../../create_order/presentation/pages/create_order_page.dart';
import '../../../order_success/data/models/order_success_args.dart';
import '../../../order_success/presentation/pages/order_success_page.dart';
import '../../../payment/data/models/payment_args.dart';
import '../../../payment/presentation/pages/payment_page.dart';
import '../../../payment/presentation/pages/payment_webview_page.dart';
// TODO(reviews): нужен только шиту отзывов — вернуть вместе с ним.
// import '../../../product/data/models/product_model.dart';
import '../../../product/presentation/pages/product_page.dart';
// TODO(reviews): отзывы временно отключены целиком.
// import '../../../product/presentation/pages/product_reviews_page.dart';
import '../../../seller/presentation/pages/seller_store_page.dart';

/// Метка на каждом маршруте, открытом поверх стрима или сториз.
///
/// Публичная: любой шит, который может открыться внутри этого стека, обязан
/// проставить её сам, иначе `closeAll` упрётся в него и молча перестанет
/// работать для всего, что выше.
const String kLiveSheetRouteName = 'live_shopping_sheet';

/// Максимальная глубина стека шитов.
///
/// Без ограничения цепочка `эфир → товар → магазин → товар → …` растёт
/// бесконечно, и каждый шит держит живыми свои кубиты поверх идущей
/// WebRTC-сессии. На пределе новый шит заменяет верхний, а не ложится сверху.
const int kMaxLiveSheetDepth = 4;

/// Проводит покупку через стек модальных шитов, пока под ними продолжает идти
/// видео (или сториз).
///
/// Если [LiveShoppingScope.maybeOf] возвращает не-null, страницы обязаны звать
/// этот контроллер вместо `context.push` / `context.go` — иначе навигация
/// уводит с экрана и рвёт стрим.
class LiveShoppingController {
  /// Контроллер полноэкранного «хозяина» — экрана эфира или просмотрщика
  /// сториз.
  ///
  /// Нужен виджетам, которые живут **над** роутером и не видят наш
  /// InheritedWidget: плашке корзины, разбору 401 в `app_dio`, роутеру пушей.
  static LiveShoppingController? _current;
  static LiveShoppingController? get current => _current;

  /// Зовётся из `initState` экрана-хозяина.
  static void register(LiveShoppingController controller) {
    assert(
      _current == null,
      'Полноэкранный хозяин может быть только один: сейчас зарегистрирован '
      'другой. Проверьте, что unregister() вызывается в dispose().',
    );
    _current = controller;
  }

  /// Зовётся из `dispose` экрана-хозяина.
  static void unregister() => _current = null;

  int _depth = 0;

  Future<void> openCart(BuildContext context) =>
      _openSheet(context, const _CartTarget());

  Future<void> openProduct(BuildContext context, int id) =>
      _openSheet(context, _ProductTarget(id));

  Future<void> openCreateOrder(BuildContext context, CartModel cart) =>
      _openSheet(context, _CreateOrderTarget(cart));

  Future<void> openPayment(BuildContext context, PaymentArgs args) =>
      _openSheet(context, _PaymentTarget(args));

  Future<void> openPaymentWebview(BuildContext context, PaymentArgs args) =>
      _openSheet(context, _PaymentWebviewTarget(args));

  Future<void> openOrderSuccess(BuildContext context, OrderSuccessArgs args) =>
      _openSheet(context, _OrderSuccessTarget(args));

  /// Любой шит, открывающийся внутри стрима, — с проставленной меткой.
  ///
  /// Отдельный метод, чтобы про метку нельзя было забыть: раньше половина
  /// шитов открывалась без неё и превращала `closeAll` в no-op.
  Future<T?> openTagged<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    Color? barrierColor,
    Color backgroundColor = Colors.transparent,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor,
      barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.4),
      routeSettings: const RouteSettings(name: kLiveSheetRouteName),
      builder: (sheetCtx) =>
          LiveShoppingScope(controller: this, child: builder(sheetCtx)),
    );
  }

  /// Схлопывает все свои шиты обратно к экрану-хозяину.
  ///
  /// Предикат намеренно завязан на метку, а не на имя маршрута эфира: под
  /// стеком может лежать и просмотрщик сториз, и якорь на `'/live/:id'` его бы
  /// снёс. `isFirst` — страховка, чтобы нельзя было выпоповать всё приложение,
  /// если какой-то маршрут остался без метки.
  void closeAll(BuildContext context) {
    Navigator.of(context).popUntil(
      (route) => route.settings.name != kLiveSheetRouteName || route.isFirst,
    );
    _depth = 0;
  }

  /// То же, но затем уводит нижний стек go_router.
  /// Используется «Посмотреть статус» на экране успешного заказа.
  void closeAllAndGo(BuildContext context, String location) {
    final router = GoRouter.of(context);
    closeAll(context);
    router.go(location);
  }

  Future<void> _openSheet(BuildContext context, _SheetTarget target) async {
    // На пределе глубины верхний шит уступает место новому, иначе стек растёт
    // без границы.
    if (_depth >= kMaxLiveSheetDepth) {
      Navigator.of(context).pop();
      _depth--;
    }
    _depth++;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.55),
        routeSettings: const RouteSettings(name: kLiveSheetRouteName),
        builder: (sheetCtx) {
          return LiveShoppingScope(
            controller: this,
            child: _LiveSheetFrame(child: target.build(this, sheetCtx)),
          );
        },
      );
    } finally {
      if (_depth > 0) _depth--;
    }
  }
}

class LiveShoppingScope extends InheritedWidget {
  const LiveShoppingScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final LiveShoppingController controller;

  /// Не-null означает «мы внутри стека шитов», а НЕ «мы на экране эфира».
  /// Сториз пользуются тем же стеком.
  static LiveShoppingController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<LiveShoppingScope>()
      ?.controller;

  @override
  bool updateShouldNotify(LiveShoppingScope oldWidget) =>
      controller != oldWidget.controller;
}

/// Контроллер для текущего места: свой из стека шитов, иначе контроллер
/// экрана-хозяина, иначе новый (первый шит поверх обычного экрана).
LiveShoppingController _resolve(BuildContext context) =>
    LiveShoppingScope.maybeOf(context) ??
    LiveShoppingController.current ??
    LiveShoppingController();

/// Точки входа с самого экрана эфира и из сториз.
Future<void> openLiveCartSheet(BuildContext context) =>
    _resolve(context).openCart(context);

Future<void> openLiveProductSheet(BuildContext context, int id) =>
    _resolve(context).openProduct(context, id);

/// Перейти по маршруту, не покидая стрим.
///
/// Внутри стрима — шит поверх видео, снаружи — обычный `context.push`. Один
/// вызов вместо пятистрочного if/else на каждом сайте: раньше половина мест
/// про эту ветку просто забывала.
Future<void> liveAwarePush(
  BuildContext context,
  String location, {
  Object? extra,
}) {
  final controller = LiveShoppingScope.maybeOf(context) ??
      LiveShoppingController.current;
  if (controller == null) {
    context.push(location, extra: extra); // live-nav-ok
    return Future.value();
  }
  final target = _targetFor(location, extra);
  if (target == null) {
    // Новый маршрут, о котором тут не знают. В отладке падаем, в проде — уводим
    // как раньше: лучше выйти из стрима, чем не открыть экран вовсе.
    assert(false, 'Нет шита для $location — добавьте цель в _targetFor');
    context.push(location, extra: extra); // live-nav-ok
    return Future.value();
  }
  return controller._openSheet(context, target);
}

/// Открыть виджет, у которого нет маршрута (полноэкранные просмотрщики,
/// которые сейчас открываются сырым `Navigator.push`).
Future<T?> liveAwarePushWidget<T>(BuildContext context, Widget page) {
  final controller = LiveShoppingScope.maybeOf(context) ??
      LiveShoppingController.current;
  // Метку ставим всегда — даже вне стрима это ничего не ломает, зато шит,
  // открытый из уже открытого шита, гарантированно попадёт под closeAll.
  return Navigator.of(context).push<T>(
    MaterialPageRoute<T>(
      settings: const RouteSettings(name: kLiveSheetRouteName),
      builder: (ctx) => controller == null
          ? page
          : LiveShoppingScope(controller: controller, child: page),
    ),
  );
}

/// «Этого экрана больше нет»: внутри стрима возвращаемся к нему, снаружи — на
/// главную. Для удалённого товара и подобных тупиков.
void liveAwareDismiss(BuildContext context) {
  final controller = LiveShoppingScope.maybeOf(context) ??
      LiveShoppingController.current;
  if (controller != null) {
    controller.closeAll(context);
    return;
  }
  context.go('/main'); // live-nav-ok
}

/// Осознанный выход: схлопнуть шиты и уйти по маршруту. Стрим при этом
/// прерывается — так и задумано («Посмотреть статус заказа»).
void liveAwareGo(BuildContext context, String location) {
  final controller = LiveShoppingScope.maybeOf(context) ??
      LiveShoppingController.current;
  if (controller != null) {
    controller.closeAllAndGo(context, location);
    return;
  }
  context.go(location); // live-nav-ok
}

/// Схлопнуть шиты откуда угодно, включая виджеты над роутером.
///
/// Нужно интерцептору 401: он подменяет весь стек go_router, а шиты и
/// экран-хозяин остаются висеть поверх экрана авторизации.
void closeLiveSheetsFrom(BuildContext? context) {
  final controller = LiveShoppingController.current;
  if (controller == null || context == null || !context.mounted) return;
  controller.closeAll(context);
}

/// Маршрут → шит. Разбирается по сегментам пути, как в `app_routing.dart`, с
/// такими же guard-ами по типу `extra`.
_SheetTarget? _targetFor(String location, Object? extra) {
  final segments = Uri.parse(location).pathSegments;
  if (segments.isEmpty) return null;

  switch (segments.first) {
    case 'cart':
      return const _CartTarget();
    case 'product':
      final id = int.tryParse(segments.length > 1 ? segments[1] : '');
      if (id == null) return null;
      // TODO(reviews): отзывы временно отключены целиком.
      // if (segments.length > 2 && segments[2] == 'reviews') {
      //   return extra is ProductModel ? _ReviewsTarget(extra) : null;
      // }
      return _ProductTarget(id);
    case 'seller':
      final id = int.tryParse(segments.length > 1 ? segments[1] : '');
      if (id == null) return null;
      String? title;
      if (extra is Map && extra['title'] is String) {
        title = extra['title'] as String;
      }
      return _SellerTarget(id, title);
    case 'make_order':
      return extra is CartModel ? _CreateOrderTarget(extra) : null;
    case 'payment':
      return extra is PaymentArgs ? _PaymentTarget(extra) : null;
    case 'payment_webview':
      return extra is PaymentArgs ? _PaymentWebviewTarget(extra) : null;
    case 'order_success':
      return extra is OrderSuccessArgs ? _OrderSuccessTarget(extra) : null;
  }
  return null;
}

class _LiveSheetFrame extends StatelessWidget {
  const _LiveSheetFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SizedBox(height: double.infinity, child: child),
    );
  }
}

@immutable
abstract class _SheetTarget {
  const _SheetTarget();
  Widget build(LiveShoppingController controller, BuildContext context);
}

class _CartTarget extends _SheetTarget {
  const _CartTarget();
  @override
  Widget build(LiveShoppingController controller, BuildContext context) {
    // Без toCatalog кнопка «К покупкам» в пустой корзине внутри стрима была
    // мёртвой: уводить в каталог отсюда нельзя, а закрыть шиты — можно.
    return CartPage(toCatalog: () => controller.closeAll(context));
  }
}

class _ProductTarget extends _SheetTarget {
  const _ProductTarget(this.id);
  final int id;
  @override
  Widget build(LiveShoppingController controller, BuildContext context) =>
      ProductPage(id: id.toString());
}

class _SellerTarget extends _SheetTarget {
  const _SellerTarget(this.id, this.titleOverride);
  final int id;
  final String? titleOverride;
  @override
  Widget build(LiveShoppingController controller, BuildContext context) =>
      SellerStorePage(id: id, titleOverride: titleOverride);
}

// TODO(reviews): отзывы временно отключены целиком.
// class _ReviewsTarget extends _SheetTarget {
//   const _ReviewsTarget(this.product);
//   final ProductModel product;
//   @override
//   Widget build(LiveShoppingController controller, BuildContext context) =>
//       ProductReviewsPage(product: product);
// }

class _CreateOrderTarget extends _SheetTarget {
  const _CreateOrderTarget(this.cart);
  final CartModel cart;
  @override
  Widget build(LiveShoppingController controller, BuildContext context) =>
      CreateOrderPage(cartModel: cart);
}

class _PaymentTarget extends _SheetTarget {
  const _PaymentTarget(this.args);
  final PaymentArgs args;
  @override
  Widget build(LiveShoppingController controller, BuildContext context) =>
      PaymentPage(args: args);
}

class _PaymentWebviewTarget extends _SheetTarget {
  const _PaymentWebviewTarget(this.args);
  final PaymentArgs args;
  @override
  Widget build(LiveShoppingController controller, BuildContext context) =>
      PaymentWebViewPage(args: args);
}

class _OrderSuccessTarget extends _SheetTarget {
  const _OrderSuccessTarget(this.args);
  final OrderSuccessArgs args;
  @override
  Widget build(LiveShoppingController controller, BuildContext context) =>
      OrderSuccessPage(args: args);
}
