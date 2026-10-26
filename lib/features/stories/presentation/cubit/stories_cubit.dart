import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/stories_services.dart';
import '../../data/models/story_group_model.dart';
import '../../data/models/story_model.dart';
import '../../domain/repositories/stories_repository.dart';

part 'stories_state.dart';

/// Лента сториз продавцов.
///
/// Ленивый, как и лента эфиров: `StreamsPage` постоянно смонтирована в
/// `IndexedStack`, поэтому загрузку запускает открытие вкладки, а не
/// `initState`.
class StoriesCubit extends Cubit<StoriesState> {
  StoriesCubit({StoriesRepository? repository})
      : _repo = repository ?? StoriesServices(),
        super(const StoriesState());

  final StoriesRepository _repo;
  bool _loadedOnce = false;

  /// Гость получил 401 на отметку просмотра — дальше не пробуем.
  bool _authBlocked = false;

  Future<void> ensureLoaded() async {
    if (_loadedOnce) return;
    _loadedOnce = true;
    await load();
  }

  Future<void> load({bool silent = false}) async {
    if (isClosed) return;
    if (!silent) emit(state.copyWith(status: StoriesStatus.loading));

    final result = await _repo.getStories();
    if (isClosed) return;
    switch (result) {
      case StoriesFeedLoaded(:final groups):
        emit(state.copyWith(status: StoriesStatus.loaded, groups: groups));
      case StoriesFeedFailed():
        // Фоновое обновление не должно стирать уже показанные кружки.
        if (silent && state.groups.isNotEmpty) return;
        emit(state.copyWith(status: StoriesStatus.error));
    }
  }

  Future<void> refresh() => load(silent: state.groups.isNotEmpty);

  /// Отметить сториз просмотренной.
  ///
  /// Оптимистично: кольцо сереет сразу, до ответа сервера. Откат в рамках
  /// сессии не делаем — «серое кольцо при пропавшей сети» пользователю понятнее,
  /// чем мигающее, а следующая загрузка ленты всё сверит.
  Future<void> markViewed(int storyId) async {
    if (_authBlocked || state.isStoryViewed(storyId)) return;
    emit(state.copyWith(viewedIds: {...state.viewedIds, storyId}));

    final result = await _repo.markViewed(storyId);
    if (isClosed) return;
    switch (result) {
      case MarkStoryViewedOk():
        break;
      case MarkStoryViewedGone():
        // Протухла — убираем из ленты, чтобы не открылась снова.
        emit(state.copyWith(groups: _withoutStory(storyId)));
      case MarkStoryViewedUnauthorized():
        _authBlocked = true;
      case MarkStoryViewedFailed():
        break;
    }
  }

  List<StoryGroupModel> _withoutStory(int storyId) {
    final groups = <StoryGroupModel>[];
    for (final group in state.groups) {
      final rest = group.stories.where((s) => s.id != storyId).toList();
      if (rest.isEmpty) continue;
      groups.add(group.copyWith(stories: rest));
    }
    return groups;
  }
}
