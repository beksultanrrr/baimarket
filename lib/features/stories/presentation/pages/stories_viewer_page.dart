import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/services/app_logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../live/presentation/widgets/live_shopping_scope.dart';
import '../../data/models/story_group_model.dart';
import '../../data/models/story_model.dart';
import '../cubit/stories_cubit.dart';
import '../widgets/story_progress_bar.dart';
import '../widgets/story_video_cache.dart';

/// Открывает просмотрщик сториз.
///
/// Локальный `PageRouteBuilder`, а не маршрут go_router: при TTL в 24 часа
/// диплинк бесполезен, `state.extra` со списком групп не переживает hot
/// restart, а просмотрщику нужен страничный кубит через `BlocProvider.value`.
Future<void> openStoriesViewer(
  BuildContext context, {
  required StoriesCubit cubit,
  required int initialGroupIndex,
}) {
  // live-nav-ok: это и есть открытие самого просмотрщика
  return Navigator.of(context).push(
    PageRouteBuilder(
      // Имя маршрута читают плашка корзины и отступы нижней панели.
      settings: const RouteSettings(name: 'stories_viewer'),
      opaque: true,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => BlocProvider.value(
        value: cubit,
        child: StoriesViewerPage(initialGroupIndex: initialGroupIndex),
      ),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// Полноэкранный просмотр сториз.
class StoriesViewerPage extends StatefulWidget {
  const StoriesViewerPage({super.key, required this.initialGroupIndex});

  final int initialGroupIndex;

  @override
  State<StoriesViewerPage> createState() => _StoriesViewerPageState();
}

class _StoriesViewerPageState extends State<StoriesViewerPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  /// Сколько показываем картинку. Видео идёт свою длительность.
  static const Duration _imageDuration = Duration(seconds: 5);

  /// Если видео не инициализировалось за это время — пропускаем.
  static const Duration _videoWatchdog = Duration(seconds: 10);

  /// Дожидаемся, что сториз действительно посмотрели.
  ///
  /// Без задержки пролистывание правого края группы из восьми сториз шлёт
  /// восемь POST-ов за секунду за контент, которого никто не видел.
  static const Duration _viewDebounce = Duration(milliseconds: 700);

  /// Один контроллер на весь экран: никаких Timer.periodic и setState на
  /// каждый кадр. Он же даёт паузу по долгому нажатию с продолжением с того
  /// же места.
  late final AnimationController _anim;
  late final PageController _pages;
  late final StoryVideoCache _videos;

  int _groupIndex = 0;
  int _storyIndex = 0;
  Timer? _viewTimer;
  Timer? _watchdog;
  bool _muted = true;
  bool _buffering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _groupIndex = widget.initialGroupIndex;
    _pages = PageController(initialPage: _groupIndex);
    _videos = StoryVideoCache();
    _anim = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _next();
      });
    // Пока открыт просмотрщик, покупка идёт шитами поверх него — как в эфире.
    LiveShoppingController.register(LiveShoppingController());
    WidgetsBinding.instance.addPostFrameCallback((_) => _playCurrent());
  }

  @override
  void dispose() {
    LiveShoppingController.unregister();
    WidgetsBinding.instance.removeObserver(this);
    _viewTimer?.cancel();
    _watchdog?.cancel();
    _anim.dispose();
    _pages.dispose();
    _videos.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    // В фоне останавливаемся, но при возврате сами не продолжаем: человек
    // должен увидеть кадр, а не пропущенную сториз.
    _anim.stop();
    _videos.pauseCurrent();
  }

  List<StoryGroupModel> get _groups => context.read<StoriesCubit>().state.groups;

  StoryGroupModel? get _group {
    final groups = _groups;
    if (_groupIndex < 0 || _groupIndex >= groups.length) return null;
    return groups[_groupIndex];
  }

  StoryModel? get _story {
    final stories = _group?.stories;
    if (stories == null || _storyIndex < 0 || _storyIndex >= stories.length) {
      return null;
    }
    return stories[_storyIndex];
  }

  Future<void> _playCurrent() async {
    _viewTimer?.cancel();
    _watchdog?.cancel();
    _anim.stop();

    final story = _story;
    if (story == null) {
      _close();
      return;
    }

    if (!story.isVideo) {
      setState(() => _buffering = false);
      _anim
        ..duration = _imageDuration
        ..forward(from: 0);
      _scheduleViewed(story.id);
      _preloadNext();
      return;
    }

    setState(() => _buffering = true);
    // Пока буферизуемся, прогресс держим на нуле — иначе часы тикают на
    // спиннере и человек «не успевает» посмотреть.
    _watchdog = Timer(_videoWatchdog, () {
      storiesLog.warn('видео не готово за 10s — пропускаем', 'story=${story.id}');
      _next();
    });

    final controller = await _videos.controllerFor(story);
    if (!mounted || _story?.id != story.id) return;
    _watchdog?.cancel();

    if (controller == null) {
      storiesLog.warn('видео не загрузилось', 'story=${story.id}');
      // Красный экран здесь никому не нужен: считаем просмотренной и идём
      // дальше, чтобы одна битая сториз не запирала всю группу.
      unawaited(context.read<StoriesCubit>().markViewed(story.id));
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (mounted) _next();
      return;
    }

    await controller.setVolume(_muted ? 0 : 1);
    final duration = controller.value.duration;
    _anim
      ..duration = duration > Duration.zero
          ? duration
          : const Duration(seconds: 15)
      ..forward(from: 0);
    await controller.play();
    if (!mounted) return;
    setState(() => _buffering = false);
    _scheduleViewed(story.id);
    _preloadNext();
  }

  void _scheduleViewed(int storyId) {
    _viewTimer?.cancel();
    _viewTimer = Timer(_viewDebounce, () {
      if (!mounted) return;
      context.read<StoriesCubit>().markViewed(storyId);
    });
  }

  /// Предзагрузка следующего кадра, чтобы переход не был чёрным.
  void _preloadNext() {
    final group = _group;
    if (group == null) return;
    if (_storyIndex + 1 < group.stories.length) {
      final next = group.stories[_storyIndex + 1];
      if (next.isVideo) {
        unawaited(_videos.preload(next));
      } else if (next.fullUrl.isNotEmpty) {
        unawaited(precacheImage(NetworkImage(next.fullUrl), context));
      }
      return;
    }
    // Конец группы — греем первую сториз следующего продавца.
    final groups = _groups;
    if (_groupIndex + 1 < groups.length) {
      final nextGroup = groups[_groupIndex + 1];
      if (nextGroup.stories.isEmpty) return;
      final first = nextGroup.stories.first;
      if (!first.isVideo && first.fullUrl.isNotEmpty) {
        unawaited(precacheImage(NetworkImage(first.fullUrl), context));
      }
    }
  }

  void _next() {
    final group = _group;
    if (group == null) return _close();
    if (_storyIndex + 1 < group.stories.length) {
      setState(() => _storyIndex++);
      _playCurrent();
      return;
    }
    _nextGroup();
  }

  void _prev() {
    if (_storyIndex > 0) {
      setState(() => _storyIndex--);
      _playCurrent();
      return;
    }
    if (_groupIndex > 0) {
      _pages.jumpToPage(_groupIndex - 1);
      return;
    }
    // Первая сториз первой группы — просто начинаем сначала.
    _playCurrent();
  }

  void _nextGroup() {
    if (_groupIndex + 1 < _groups.length) {
      _pages.jumpToPage(_groupIndex + 1);
    } else {
      _close();
    }
  }

  void _onGroupChanged(int index) {
    setState(() {
      _groupIndex = index;
      _storyIndex = 0;
    });
    _playCurrent();
  }

  void _pauseForSheet() {
    _anim.stop();
    _viewTimer?.cancel();
    _videos.pauseCurrent();
  }

  void _resumeAfterSheet() {
    _videos.playCurrent();
    _anim.forward();
  }

  Future<void> _openProduct(int modelId) async {
    _pauseForSheet();
    // Тот же стек шитов, что и в эфире: корзина, оформление и оплата остаются
    // поверх поставленной на паузу сториз.
    await openLiveProductSheet(context, modelId);
    if (!mounted) return;
    _resumeAfterSheet();
  }

  Future<void> _toggleSound() async {
    setState(() => _muted = !_muted);
    await _videos.setMuted(_muted);
  }

  void _close() {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    if (groups.isEmpty) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // Только вертикальный жест: Dismissible дрался бы с PageView.
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 200) _close();
        },
        onLongPressStart: (_) {
          _anim.stop();
          _videos.pauseCurrent();
        },
        onLongPressEnd: (_) {
          _videos.playCurrent();
          _anim.forward();
        },
        child: PageView.builder(
          controller: _pages,
          itemCount: groups.length,
          onPageChanged: _onGroupChanged,
          itemBuilder: (context, index) {
            // Рисуем только текущую группу: соседние страницы PageView строит
            // заранее, а держать их медиа живыми незачем.
            if (index != _groupIndex) {
              return const ColoredBox(color: Colors.black);
            }
            return _GroupView(
              group: groups[index],
              storyIndex: _storyIndex,
              progress: _anim,
              buffering: _buffering,
              muted: _muted,
              videoController: _videos.current,
              onTapLeft: _prev,
              onTapRight: _next,
              onClose: _close,
              onToggleSound: _toggleSound,
              onOpenProduct: _openProduct,
            );
          },
        ),
      ),
    );
  }
}

class _GroupView extends StatelessWidget {
  const _GroupView({
    required this.group,
    required this.storyIndex,
    required this.progress,
    required this.buffering,
    required this.muted,
    required this.videoController,
    required this.onTapLeft,
    required this.onTapRight,
    required this.onClose,
    required this.onToggleSound,
    required this.onOpenProduct,
  });

  final StoryGroupModel group;
  final int storyIndex;
  final Animation<double> progress;
  final bool buffering;
  final bool muted;
  final VideoPlayerController? videoController;
  final VoidCallback onTapLeft;
  final VoidCallback onTapRight;
  final VoidCallback onClose;
  final VoidCallback onToggleSound;
  final ValueChanged<int> onOpenProduct;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (group.stories.isEmpty) return const ColoredBox(color: Colors.black);
    final safeIndex = storyIndex.clamp(0, group.stories.length - 1);
    final story = group.stories[safeIndex];

    return Stack(
      fit: StackFit.expand,
      children: [
        _Media(
          story: story,
          controller: videoController,
          buffering: buffering,
        ),
        // Зоны тапа под контентом шапки, но над медиа.
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTapLeft,
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTapRight,
              ),
            ),
          ],
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xB3000000), Colors.transparent],
                  stops: [0.0, 0.28],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: StoryProgressBar(
                  count: group.stories.length,
                  currentIndex: safeIndex,
                  progress: progress,
                ),
              ),
              _Header(
                name: group.seller.displayName,
                muted: muted,
                showSound: story.isVideo,
                onToggleSound: onToggleSound,
                onClose: onClose,
              ),
              const Spacer(),
              if (story.modelId != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: _ProductCta(
                    label: l10n.storyOpenProduct,
                    onTap: () => onOpenProduct(story.modelId!),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Media extends StatelessWidget {
  const _Media({
    required this.story,
    required this.controller,
    required this.buffering,
  });

  final StoryModel story;
  final VideoPlayerController? controller;
  final bool buffering;

  @override
  Widget build(BuildContext context) {
    if (story.isVideo) {
      final vc = controller;
      if (vc == null || !vc.value.isInitialized || buffering) {
        return const ColoredBox(
          color: Colors.black,
          child: Center(
            child: CircularProgressIndicator(color: Colors.white24, strokeWidth: 2),
          ),
        );
      }
      // FittedBox поверх собственного размера видео, а не AspectRatio: тот
      // оставил бы поля сверху и снизу на вертикальном экране.
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: vc.value.size.width,
          height: vc.value.size.height,
          child: VideoPlayer(vc),
        ),
      );
    }

    final url = story.fullUrl;
    if (url.isEmpty) return const ColoredBox(color: Colors.black);
    // NetworkImageWidget здесь не подходит: его светло-серая брендовая
    // заглушка на чёрном полноэкранном фоне читается как настоящее фото.
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const ColoredBox(
          color: Colors.black,
          child: Center(
            child: CircularProgressIndicator(color: Colors.white24, strokeWidth: 2),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.muted,
    required this.showSound,
    required this.onToggleSound,
    required this.onClose,
  });

  final String name;
  final bool muted;
  final bool showSound;
  final VoidCallback onToggleSound;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          if (showSound)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
              onPressed: onToggleSound,
              child: Icon(
                muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(36, 36),
            onPressed: onClose,
            child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}

class _ProductCta extends StatelessWidget {
  const _ProductCta({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/stream/action_bag.svg',
                width: 18,
                height: 18,
                colorFilter:
                    const ColorFilter.mode(Colors.black, BlendMode.srcIn),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
