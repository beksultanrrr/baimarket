import 'dart:async';
import 'package:flutter/material.dart';

/// Карусель промо-баннеров на главной. Использует локальные ассеты
/// `assets/images/baner{1,2,3}.png` — сетевая загрузка через
/// `MainCubit/banners` больше не используется (но cubit оставлен,
/// чтобы не ломать другие места). Размер баннера фиксированный 350×320,
/// центрирован, шире не растягивается даже на широких экранах.
class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({super.key});

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  static const _assets = ['assets/images/baner1.png', 'assets/images/baner2.png', 'assets/images/baner3.png'];

  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1000, viewportFraction: 1.0);
    _startAutoSlide();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoSlideTimer?.cancel();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      _pageController.nextPage(duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.29,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index % _assets.length);
            },
            itemBuilder: (context, index) {
              final asset = _assets[index % _assets.length];
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: double.infinity, maxHeight: MediaQuery.of(context).size.height * 0.29),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(asset, fit: BoxFit.fill, width: double.infinity, height: double.infinity),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _assets.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: _currentIndex == i ? Colors.white : Colors.white.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
