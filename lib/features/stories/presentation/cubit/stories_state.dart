part of 'stories_cubit.dart';

enum StoriesStatus { initial, loading, loaded, error }

class StoriesState extends Equatable {
  const StoriesState({
    this.status = StoriesStatus.initial,
    this.groups = const [],
    this.viewedIds = const {},
  });

  final StoriesStatus status;
  final List<StoryGroupModel> groups;

  /// Локальный оверлей «просмотрено в этой сессии».
  ///
  /// Именно он даёт кольцу посереть сразу, без перезагрузки ленты. Держим
  /// отдельным множеством, а не правкой моделей: `hasUnviewed` с сервера
  /// после первой же отметки устаревает, и два источника правды разошлись бы.
  final Set<int> viewedIds;

  bool get isEmpty => status == StoriesStatus.loaded && groups.isEmpty;

  bool isStoryViewed(int storyId) => viewedIds.contains(storyId);

  /// Просмотрена ли сториз с учётом и сервера, и локальных отметок.
  bool isViewed(StoryModel story) => story.isViewed || isStoryViewed(story.id);

  /// Есть ли у продавца непросмотренные. Всегда вычисляется, никогда не
  /// хранится — поэтому не может разойтись с самими сториз.
  bool groupHasUnviewed(StoryGroupModel group) =>
      group.stories.any((s) => !isViewed(s));

  StoriesState copyWith({
    StoriesStatus? status,
    List<StoryGroupModel>? groups,
    Set<int>? viewedIds,
  }) {
    return StoriesState(
      status: status ?? this.status,
      groups: groups ?? this.groups,
      viewedIds: viewedIds ?? this.viewedIds,
    );
  }

  @override
  List<Object?> get props => [
        status,
        groups.length,
        // Иначе смена набора при том же количестве групп не долетит до UI.
        groups.map((g) => '${g.seller.id}:${g.stories.length}').join(','),
        viewedIds.length,
      ];
}
