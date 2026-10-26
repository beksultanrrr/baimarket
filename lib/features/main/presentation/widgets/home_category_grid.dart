import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class _Tile {
  final String slug;

  /// Целиковая плитка из Figma: градиентный фон + арт, БЕЗ подписи.
  /// Текст в макете запечён в пути, поэтому из ассетов он вырезан и
  /// рисуется поверх Flutter-виджетом — иначе плитка не локализуется.
  final String tileAsset;

  /// Заглушка на первый кадр, пока flutter_svg парсит ассет.
  /// Примерно средний тон градиента из [tileAsset].
  final Color background;
  final Map<String, String> labels;

  const _Tile({required this.slug, required this.tileAsset, required this.background, required this.labels});

  String labelFor(String locale) {
    return labels[locale] ?? labels['ru'] ?? labels.values.first;
  }
}

// Призы — на бэке коллекция `lottery` (аукционные призы). Frame 18610.
const _prizeTile = _Tile(
  slug: 'lottery',
  tileAsset: 'assets/icons/main/tile_prize.svg',
  background: Color(0xFFF9AE62),
  labels: {'ru': 'Призы', 'kk': 'Сыйлықтар', 'en': 'Prizes'},
);

// Новинки — на бэке коллекция `new`. Frame 18609.
const _newTile = _Tile(
  slug: 'new',
  tileAsset: 'assets/icons/main/tile_new.svg',
  background: Color(0xFFFF6E8C),
  labels: {'ru': 'Новинки', 'kk': 'Жаңалықтар', 'en': 'New'},
);

// Хиты — отдельной коллекции `hit` на бэке нет, кидаем во весь каталог `all`.
// Frame 18611.
const _hitTile = _Tile(
  slug: 'all',
  tileAsset: 'assets/icons/main/tile_hit.svg',
  background: Color(0xFF9B7FDA),
  labels: {'ru': 'Хиты', 'kk': 'Хиттер', 'en': 'Hits'},
);

// Скидки — на бэке коллекция `discount`. Frame 18614.
const _salesTile = _Tile(
  slug: 'discount',
  tileAsset: 'assets/icons/main/tile_sales.svg',
  background: Color(0xFF6BB44F),
  labels: {'ru': 'Скидки', 'kk': 'Жеңіл-\nдіктер', 'en': 'Discounts'},
);

// Весь каталог — 4 квадрата справа. Frame 18613.
const _allTile = _Tile(
  slug: 'all',
  tileAsset: 'assets/icons/main/tile_all.svg',
  background: Color(0xFF333333),
  labels: {'ru': 'Весь\nКаталог', 'kk': 'Барлық\nкаталог', 'en': 'Whole\nCatalog'},
);

class HomeCategoryGrid extends StatelessWidget {
  const HomeCategoryGrid({super.key, this.onAllCatalog});

  /// Когда указан — плитка «Весь Каталог» вызывает этот колбэк
  /// (переключение на таб «Каталог» внутри `MenuPage`) вместо пуша
  /// на `/collection/all`.
  final VoidCallback? onAllCatalog;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    // Бэк отдаёт 3 коллекции (`new`, `discount`, `lottery`) + спец-slug
    // `all` (весь каталог). Тайл «Хиты» отдельной коллекции не имеет —
    // кидаем туда же, что и «Весь Каталог», чтобы тап не открывал пусто.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: _CategoryCard(tile: _prizeTile, height: 80, locale: locale))),
              Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: _CategoryCard(tile: _newTile, height: 80, locale: locale))),
              Expanded(child: _CategoryCard(tile: _hitTile, height: 80, locale: locale)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // 150 : 192 — ровно как в макете (150 + 8 + 192 = 350 = 390pt
              // экран минус горизонтальные отступы по 20).
              Expanded(flex: 150, child: Padding(padding: const EdgeInsets.only(right: 8), child: _CategoryCard(tile: _salesTile, height: 80, locale: locale))),
              Expanded(flex: 192, child: _CategoryCard(tile: _allTile, height: 80, locale: locale, onTapOverride: onAllCatalog)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.tile, required this.locale, this.height = 80, this.onTapOverride});

  final _Tile tile;
  final String locale;
  final double height;

  /// Если задан — берётся вместо стандартного перехода на /collection.
  /// Используется для «Весь Каталог», чтобы остаться внутри MenuPage и
  /// переключиться на таб «Каталог» (frame 16271).
  final VoidCallback? onTapOverride;

  @override
  Widget build(BuildContext context) {
    final label = tile.labelFor(locale);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        if (onTapOverride != null) {
          onTapOverride!();
          return;
        }
        context.push('/collection/${tile.slug}', extra: {'title': tile.labelFor(locale)});
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: height,
          decoration: BoxDecoration(color: tile.background, borderRadius: BorderRadius.circular(12)),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Градиент + арт целиком приезжают из Figma-ассета. BoxFit.fill,
              // а не cover: ширина плитки резиновая (Expanded), и cover обрезал
              // бы арт по высоте на широких экранах, а fill лишь чуть тянет
              // градиент по горизонтали — визуально незаметно.
              Positioned.fill(child: SvgPicture.asset(tile.tileAsset, fit: BoxFit.fill)),
              Positioned(
                top: 9,
                left: 9,
                right: 12,
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: GoogleFonts.unbounded().fontFamily, fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _InnerShadowPainter(borderRadius: BorderRadius.circular(12), offset: const Offset(4, 4), blur: 8, color: Colors.white.withValues(alpha: 0.25))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InnerShadowPainter extends CustomPainter {
  _InnerShadowPainter({required this.borderRadius, required this.offset, required this.color, this.blur = 0});

  final BorderRadius borderRadius;
  final Offset offset;
  final Color color;
  final double blur;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    canvas.save();
    canvas.clipRRect(rrect);
    canvas.saveLayer(rect, Paint());
    canvas.drawRect(rect, Paint()..color = color);
    final cut =
        Paint()
          ..color = Colors.black
          ..blendMode = BlendMode.dstOut;
    if (blur > 0) {
      cut.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    }
    canvas.drawRRect(rrect.shift(offset), cut);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _InnerShadowPainter old) => old.offset != offset || old.color != color || old.blur != blur;
}
