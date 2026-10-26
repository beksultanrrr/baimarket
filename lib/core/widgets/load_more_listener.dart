import 'package:flutter/widgets.dart';

/// Догрузка следующей страницы при подходе к концу скролла.
///
/// Реализовано через [NotificationListener], а не через `ScrollController`:
/// целевые экраны (витрина магазина, список отзывов) строят свой
/// `CustomScrollView` внутри вложенных виджетов, и контроллер пришлось бы
/// протаскивать через три слоя.
///
/// [onLoadMore] не вызывается повторно, пока предыдущий вызов не завершился,
/// поэтому кубиту достаточно своих обычных гардов — двойных запросов отсюда
/// не будет.
class LoadMoreListener extends StatefulWidget {
  const LoadMoreListener({
    super.key,
    required this.child,
    required this.onLoadMore,
    required this.hasMore,
    this.threshold = 400,
  });

  final Widget child;
  final Future<void> Function() onLoadMore;

  /// Есть ли что догружать. Пока `false` — скролл не триггерит ничего.
  final bool hasMore;

  /// За сколько пикселей до конца начинать догрузку.
  final double threshold;

  @override
  State<LoadMoreListener> createState() => _LoadMoreListenerState();
}

class _LoadMoreListenerState extends State<LoadMoreListener> {
  bool _busy = false;

  Future<void> _maybeLoad(ScrollMetrics metrics) async {
    if (_busy || !widget.hasMore) return;
    if (!metrics.hasContentDimensions) return;
    if (metrics.maxScrollExtent - metrics.pixels > widget.threshold) return;
    _busy = true;
    try {
      await widget.onLoadMore();
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification ||
            notification is ScrollEndNotification) {
          _maybeLoad(notification.metrics);
        }
        // Не поглощаем нотификацию — pull-to-refresh и вложенные скроллы
        // должны продолжать её видеть.
        return false;
      },
      child: widget.child,
    );
  }
}
