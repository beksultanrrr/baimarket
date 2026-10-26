import '../../data/models/story_group_model.dart';

/// Результат `GET /stories`.
sealed class StoriesFeedResult {
  const StoriesFeedResult();
}

/// Пустая лента — это тоже успех: `Loaded(const [])`, а не отдельный вариант.
/// Иначе «сториз нет» и «не смогли загрузить» слились бы в один экран.
class StoriesFeedLoaded extends StoriesFeedResult {
  const StoriesFeedLoaded(this.groups);
  final List<StoryGroupModel> groups;
}

class StoriesFeedFailed extends StoriesFeedResult {
  const StoriesFeedFailed();
}

/// Результат `POST /stories/:id/view`.
sealed class MarkStoryViewedResult {
  const MarkStoryViewedResult();
}

class MarkStoryViewedOk extends MarkStoryViewedResult {
  const MarkStoryViewedOk();
}

/// 404 — сториз протухла или её удалили. Для клиента это успех: показывать
/// её больше не надо.
class MarkStoryViewedGone extends MarkStoryViewedResult {
  const MarkStoryViewedGone();
}

/// Гость. Дальше отметки просмотра не шлём, чтобы не долбить ручку впустую.
class MarkStoryViewedUnauthorized extends MarkStoryViewedResult {
  const MarkStoryViewedUnauthorized();
}

class MarkStoryViewedFailed extends MarkStoryViewedResult {
  const MarkStoryViewedFailed();
}

abstract class StoriesRepository {
  /// `GET /stories` — активные непросроченные сториз, сгруппированные по
  /// продавцам. Авторизация опциональна: без токена `isViewed` всегда `false`.
  Future<StoriesFeedResult> getStories();

  /// `POST /stories/:id/view`. Идемпотентно, повторные вызовы безопасны.
  Future<MarkStoryViewedResult> markViewed(int storyId);
}
