import 'package:flutter/material.dart';
import '../../../../core/urls.dart';
import '../../../../core/widgets/show_image.dart';
import '../../data/models/product_model.dart';
import '../../../live/presentation/widgets/live_shopping_scope.dart';

/// Высота блока с фото товара. Квадратное фото рисуется внутри по contain,
/// т.е. 210×210 по центру — ровно как в макете (бутылёк 200pt в высоту).
const double _kHeroHeight = 210;

class ProductImageGrid extends StatelessWidget {
  const ProductImageGrid({super.key, required this.model});
  final ProductModel model;

  void _openFullScreen(BuildContext context, int index) {
    // Внутри эфира сырой Navigator.push лёг бы поверх стрима нетегированным
    // маршрутом и обрубил бы closeAll всему, что открыто выше.
    liveAwarePushWidget(
      context,
      _FullScreenViewer(
        urls: model.photoUrls ?? [],
        initialIndex: index,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final urls = model.photoUrls ?? [];
    if (urls.isEmpty) {
      return const SizedBox(
        height: _kHeroHeight,
        child: Center(child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey)),
      );
    }

    return SizedBox(
      height: _kHeroHeight,
      child: PageView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: urls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _openFullScreen(context, index),
            child: NetworkImageWidget(
              url: '$imgUrl${urls[index]}',
              fit: BoxFit.contain,
              fallbackColor: Colors.white,
              fallbackScale: 1,
            ),
          );
        },
      ),
    );
  }
}

class _FullScreenViewer extends StatefulWidget {
  const _FullScreenViewer({required this.urls, required this.initialIndex});
  final List<String> urls;
  final int initialIndex;

  @override
  State<_FullScreenViewer> createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<_FullScreenViewer> {
  late final PageController _controller;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB9B9B9),
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: Center(
                child: NetworkImageWidgetBlack(
                  url: '$imgUrl${widget.urls[i]}',
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_current + 1}/${widget.urls.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.urls.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _current ? 12 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _current ? Colors.white : Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
