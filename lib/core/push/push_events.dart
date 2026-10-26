import 'dart:async';

/// Шина «пришёл пуш».
///
/// Связывает две системы, которые до этого не пересекались: доставку пушей и
/// список уведомлений внутри приложения. Раньше пуш не обновлял список, а
/// список ничего не знал о пушах.
///
/// Реализована статикой с broadcast-стримом, потому что источник может быть
/// в фоновом изоляте, а подписчик — виджет над роутером.
class PushEvents {
  PushEvents._();

  static final _controller = StreamController<void>.broadcast();

  static Stream<void> get stream => _controller.stream;

  static void notify() {
    if (_controller.isClosed) return;
    _controller.add(null);
  }
}
