import 'package:bai_market/features/collection/presentation/cubit/collection_cubit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:bai_market/core/utils/translation_utils.dart';

import '../../../../core/urls.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../core/widgets/show_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/select_soring.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key, required this.slug, this.titleOverride});
  final String? slug;

  /// Если задано — шапка показывает это имя вместо `detail.nameRu`.
  /// Используется когда страница открывается из плиток каталога:
  /// все плитки идут на `slug='all'`, но имя категории каждой своё.
  final String? titleOverride;

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  late final CollectionCubit _collectionCubit;
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    _collectionCubit = CollectionCubit();
    _collectionCubit.getCollection(slug: widget.slug ?? 'new', sort: 'popular');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // controller needs l10n so initialised here on first call only
    if (!_isControllerReady) {
      controller = TextEditingController(
        text: AppLocalizations.of(context)!.sortPopular,
      );
      _isControllerReady = true;
    }
  }

  bool _isControllerReady = false;

  @override
  void dispose() {
    _collectionCubit.close();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: BlocConsumer<CollectionCubit, CollectionState>(
        bloc: _collectionCubit,
        listener: (context, state) {},
        builder: (context, state) {
          if (state is CollectionGot) {
            return Scaffold(
              backgroundColor: const Color(0xFFF7F7F7),
              extendBodyBehindAppBar: true,
              body: SafeArea(
                // Top отключаем: bg-картинка живёт внутри flexibleSpace
                // и должна простираться под статус-бар. Иначе сверху
                // светит белая полоска scaffold.backgroundColor.
                top: false,
                child: CustomScrollView(
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      pinned: false,
                      stretchTriggerOffset: 300.0,
                      expandedHeight: 200.0,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      collapsedHeight: 80,
                          actions: [
                            CupertinoButton(
                              padding: const EdgeInsets.all(0),
                              onPressed: () {
                                context.push('/notification');
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 20),
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/icons/ring.svg',
                                  ),
                                ),
                              ),
                            ),
                          ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: Builder(
                          builder: (context) {
                            final locale = Localizations.localeOf(context);
                            final hardcoded = _hardcodedHeader(widget.slug, locale);
                            final assetBg = _assetBgForSlug(widget.slug);
                            final title = widget.titleOverride ??
                                hardcoded?.$1 ??
                                TranslationUtils.getLocalizedName(
                                  context: context,
                                  nameKz: state.collection.detail.nameKz,
                                  nameRu: state.collection.detail.nameRu,
                                  nameEn: state.collection.detail.nameEn,
                                );
                            final subtitle = hardcoded?.$2 ??
                                TranslationUtils.getLocalizedDescription(
                                  context: context,
                                  descriptionKz: state.collection.detail.descriptionKz,
                                  descriptionRu: state.collection.detail.descriptionRu,
                                  descriptionEn: state.collection.detail.descriptionEn,
                                );
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                if (assetBg != null)
                                  Image.asset(assetBg, fit: BoxFit.cover)
                                else if (state.collection.detail.backgroundUrl != null &&
                                    state.collection.detail.backgroundUrl!.isNotEmpty)
                                  NetworkImageWidget(
                                    url: '$imgUrl${state.collection.detail.backgroundUrl}',
                                  )
                                else
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: _bgGradientForSlug(widget.slug),
                                    ),
                                  ),
                                const Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Color(0x4D000000),
                                        ],
                                        stops: [0.55, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          fontFamily: 'Gilroy',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: MediaQuery.of(context).size.width * 0.8,
                                        child: Text(
                                          subtitle,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w300,
                                            color: Colors.white,
                                            fontFamily: 'Gilroy',
                                          ),
                                          maxLines: 2,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${state.collection.products.length} ${l10n.products}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                CupertinoButton(
                                  padding: const EdgeInsets.all(0),
                                  onPressed: () {
                                    showSortingSelectionModal(
                                      context,
                                      controller,
                                      widget.slug ?? 'new',
                                      _collectionCubit,
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      Text(
                                        controller.text,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SvgPicture.asset(
                                        'assets/icons/sort.svg',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: state.collection.products.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                mainAxisExtent: 342,
                              ),
                              itemBuilder: (context, index) => ProductCard(
                                product: state.collection.products[index],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return const Scaffold();
          }
        },
      ),
    );
  }

  /// Local asset background for the three main category pages.
  String? _assetBgForSlug(String? slug) {
    switch (slug) {
      case 'all':      return 'assets/images/hit_bg.png';
      case 'new':      return 'assets/images/new_bg.png';
      case 'discount': return 'assets/images/sale_bg.png';
      default:         return null;
    }
  }

  /// Hardcoded (title, subtitle) for 'all', 'new', 'discount' in ru/kk/en.
  (String, String)? _hardcodedHeader(String? slug, Locale locale) {
    final lang = locale.languageCode;
    const subRu = 'Подборка выгоды - скидки до 70%';
    const subKk = 'Үздік таңдау — 70%-ға дейін жеңілдік';
    const subEn = 'Best picks — up to 70% off';
    final sub = lang == 'ru' ? subRu : lang == 'kk' ? subKk : subEn;

    switch (slug) {
      case 'all':
        final title = lang == 'ru' ? 'Хиты' : lang == 'kk' ? 'Хиттер' : 'Hits';
        return (title, sub);
      case 'new':
        final title = lang == 'ru' ? 'Новинки' : lang == 'kk' ? 'Жаңалықтар' : 'New';
        return (title, sub);
      case 'discount':
        final title = lang == 'ru' ? 'Скидки' : lang == 'kk' ? 'Жеңілдіктер' : 'Discounts';
        return (title, sub);
      default:
        return null;
    }
  }

  /// Палитра фоновых градиентов для шапки коллекции по slug-у.
  /// Цвета подобраны достаточно тёмными, чтобы белый текст был контрастным.
  /// Если slug не из списка — возвращаем нейтральный slate-градиент.
  LinearGradient _bgGradientForSlug(String? slug) {
    switch (slug) {
      case 'new':
        return const LinearGradient(
          colors: [Color(0xFF1F8E7A), Color(0xFF35B89E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'discount':
        return const LinearGradient(
          colors: [Color(0xFFE0593F), Color(0xFFFF8266)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'lottery':
        return const LinearGradient(
          colors: [Color(0xFF4F5BD5), Color(0xFF7E8AF2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'all':
        return const LinearGradient(
          colors: [Color(0xFF5F58EE), Color(0xFF8197F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF4A586B), Color(0xFF6B7A8F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}
