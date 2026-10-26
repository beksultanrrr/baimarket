import 'package:bai_market/features/stories/data/models/story_model.dart';
import 'package:bai_market/features/stories/domain/repositories/stories_repository.dart';
import 'package:bai_market/features/stories/presentation/cubit/stories_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_stories_repository.dart';

void main() {
  late FakeStoriesRepository repo;
  late StoriesCubit cubit;

  setUp(() {
    repo = FakeStoriesRepository();
    cubit = StoriesCubit(repository: repo);
  });

  tearDown(() => cubit.close());

  test('пустая лента — это загрузка, а не ошибка', () async {
    await cubit.load();
    expect(cubit.state.status, StoriesStatus.loaded);
    expect(cubit.state.isEmpty, isTrue);
  });

  test('ensureLoaded грузит один раз', () async {
    repo.feedResult = StoriesFeedLoaded([
      buildGroup(stories: [buildStory(id: 1)]),
    ]);
    await cubit.ensureLoaded();
    await cubit.ensureLoaded();
    expect(cubit.state.groups.length, 1);
  });

  test('markViewed сереет кольцо сразу, до ответа сервера', () async {
    repo.feedResult = StoriesFeedLoaded([
      buildGroup(stories: [buildStory(id: 1), buildStory(id: 2)]),
    ]);
    await cubit.load();
    final group = cubit.state.groups.single;
    expect(cubit.state.groupHasUnviewed(group), isTrue);

    await cubit.markViewed(1);
    await cubit.markViewed(2);

    // hasUnviewed всегда вычисляется по оверлею, поэтому не может разойтись
    // с флагом, который пришёл с сервера.
    expect(cubit.state.groupHasUnviewed(cubit.state.groups.single), isFalse);
  });

  test('повторная отметка не шлёт второй запрос', () async {
    repo.feedResult = StoriesFeedLoaded([
      buildGroup(stories: [buildStory(id: 1)]),
    ]);
    await cubit.load();
    await cubit.markViewed(1);
    await cubit.markViewed(1);
    expect(repo.viewedCalls, [1]);
  });

  test('404 убирает протухшую сториз из ленты', () async {
    repo.feedResult = StoriesFeedLoaded([
      buildGroup(stories: [buildStory(id: 1), buildStory(id: 2)]),
    ]);
    await cubit.load();
    repo.viewResult = const MarkStoryViewedGone();

    await cubit.markViewed(1);

    final stories = cubit.state.groups.single.stories;
    expect(stories.map((StoryModel s) => s.id), [2]);
  });

  test('401 останавливает дальнейшие отметки: гость не долбит ручку', () async {
    repo.feedResult = StoriesFeedLoaded([
      buildGroup(stories: [buildStory(id: 1), buildStory(id: 2)]),
    ]);
    await cubit.load();
    repo.viewResult = const MarkStoryViewedUnauthorized();

    await cubit.markViewed(1);
    await cubit.markViewed(2);

    expect(repo.viewedCalls, [1]);
  });

  test('неудачное фоновое обновление не стирает показанные кружки', () async {
    repo.feedResult = StoriesFeedLoaded([
      buildGroup(stories: [buildStory(id: 1)]),
    ]);
    await cubit.load();

    repo.feedResult = const StoriesFeedFailed();
    await cubit.load(silent: true);

    expect(cubit.state.groups.length, 1);
    expect(cubit.state.status, StoriesStatus.loaded);
  });

  group('StoryModel.isVideo', () {
    test('не падает на IMAGE без mediaUrl', () {
      // Наивная реализация с `mediaUrl!.endsWith(...)` роняет тут null-check,
      // и из-за short-circuit `||` счастливый путь этого не ловит.
      const story = StoryModel(id: 1, mediaUrl: null, mediaType: 'IMAGE');
      expect(story.isVideo, isFalse);
      expect(story.fullUrl, '');
    });

    test('определяет видео по mediaType и по расширению', () {
      expect(buildStory(id: 1, mediaType: 'VIDEO').isVideo, isTrue);
      const byExt = StoryModel(id: 2, mediaUrl: 'clip.mp4', mediaType: null);
      expect(byExt.isVideo, isTrue);
    });
  });
}
