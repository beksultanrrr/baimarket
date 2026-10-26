import 'package:bai_market/core/app_pallete.dart';
import 'package:bai_market/features/product/data/models/product_model.dart';
import 'package:flutter/material.dart';

import '../../../../core/urls.dart';
import '../../../../core/widgets/show_image.dart';
import '../../../live/presentation/widgets/live_shopping_scope.dart';

class ProductImagesCarousel extends StatefulWidget {
  final List<String> photoUrls;
  final ProductModel model;
  const ProductImagesCarousel({
    super.key,
    required this.photoUrls,
    required this.model,
  });

  @override
  State<ProductImagesCarousel> createState() => _ProductImagesCarouselState();
}

class _ProductImagesCarouselState extends State<ProductImagesCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openFullScreenImage(BuildContext context, int initialIndex) {
    // Внутри эфира сырой Navigator.push лёг бы нетегированным маршрутом
    // поверх стрима и обрубил бы closeAll всему, что выше.
    liveAwarePushWidget(
      context,
      FullScreenImageViewer(
        urls: widget.photoUrls,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // если фото нет — можно показать заглушку
    final urls = widget.photoUrls;
    if (urls.isEmpty) {
      return const SizedBox(
        height: 360,
        child: Center(child: Text('Нет изображений')),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: 360, // или нужную вам высоту
          width: double.infinity,
          child: PageView.builder(
            controller: _pageController,
            itemCount: urls.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder:
                (context, i) => GestureDetector(
                  onTap: () => _openFullScreenImage(context, i),
                  child: NetworkImageWidget(url: '$imgUrl${urls[i]}'),
                ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(urls.length, (i) {
                final active = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(
                    vertical: 32,
                    horizontal: 4,
                  ),
                  width: active ? 12 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? seconColor : lightGray,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              height: 32,
              child: ListView.builder(
                itemCount: widget.model.collections?.length ?? 0,
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemBuilder:
                    (context, index1) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      height: 32,
                      width: 32,
                      child: NetworkImageWidget(
                        url:
                            '$imgUrl${widget.model.collections![index1].labelUrl ?? ''}',
                      ),
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Новый класс для полноэкранного просмотра изображений
class FullScreenImageViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.urls,
    required this.initialIndex,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main image viewer with interactive viewer for zoom
          PageView.builder(
            controller: _pageController,
            itemCount: widget.urls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Center(
                  child: NetworkImageWidgetBlack(
                    url: '$imgUrl${widget.urls[index]}',
                  ),
                ),
              );
            },
          ),

          // Close button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),

          // Image counter
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${widget.urls.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),

          // Bottom pagination indicators
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.urls.length, (index) {
                  final active = index == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 12 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.grey,
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
