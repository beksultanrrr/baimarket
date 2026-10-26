import 'package:video_player/video_player.dart';

import '../../../../core/services/app_logger.dart';
import '../../data/models/story_model.dart';

/// Кэш видео-контроллеров просмотрщика сториз.
///
/// Держим максимум [maxAlive] штук: текущий и предзагруженный следующий. Один
/// `VideoPlayerController` — это полноценный ExoPlayer/AVPlayer, и трое живых
/// одновременно кладут слабый Android по памяти. Просмотрщик сам ничего не
/// диспозит: вся эта бухгалтерия здесь.
class StoryVideoCache {
  static const int maxAlive = 2;

  final Map<int, VideoPlayerController> _controllers = {};
  final List<int> _order = [];
  int? _currentId;

  VideoPlayerController? get current =>
      _currentId == null ? null : _controllers[_currentId];

  /// Готовый к воспроизведению контроллер или `null`, если видео не открылось.
  Future<VideoPlayerController?> controllerFor(StoryModel story) async {
    final controller = await _ensure(story);
    if (controller == null) return null;
    _currentId = story.id;
    return controller;
  }

  /// Прогреть следующее видео, не запуская его.
  Future<void> preload(StoryModel story) => _ensure(story);

  Future<VideoPlayerController?> _ensure(StoryModel story) async {
    final existing = _controllers[story.id];
    if (existing != null) return existing;

    final url = story.fullUrl;
    if (url.isEmpty) return null;

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      // Молчим по умолчанию и не перебиваем чужую музыку: сториз открывают
      // мимоходом, и звук в лицо здесь — худшее, что можно сделать.
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    try {
      await controller.initialize();
      await controller.setVolume(0);
      await controller.setLooping(false);
    } catch (e) {
      storiesLog.warn('video init failed', '${story.id}: $e');
      await controller.dispose();
      return null;
    }

    _controllers[story.id] = controller;
    _order.add(story.id);
    _evictIfNeeded();
    return controller;
  }

  void _evictIfNeeded() {
    while (_order.length > maxAlive) {
      // Текущее видео не выселяем ни при каких обстоятельствах.
      final victimIndex = _order.indexWhere((id) => id != _currentId);
      if (victimIndex < 0) return;
      final victimId = _order.removeAt(victimIndex);
      _controllers.remove(victimId)?.dispose();
    }
  }

  Future<void> setMuted(bool muted) async {
    final controller = current;
    if (controller == null) return;
    await controller.setVolume(muted ? 0 : 1);
  }

  void pauseCurrent() => current?.pause();

  void playCurrent() => current?.play();

  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _order.clear();
    _currentId = null;
  }
}
