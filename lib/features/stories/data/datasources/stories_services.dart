import 'package:dio/dio.dart';

import '../../../../core/network/app_dio.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/urls.dart';
import '../../domain/repositories/stories_repository.dart';
import '../models/story_group_model.dart';
import '../models/story_model.dart';

class StoriesServices implements StoriesRepository {
  /// Лента с опциональной авторизацией: вкладка «Эфиры» открыта гостю, а
  /// `appDio` без токена отклоняет запрос локально синтетическим 401 и до сети
  /// не доходит — гость увидел бы пустой ряд всегда.
  final Dio _publicDio = optionalAuthDio;

  /// Отметка просмотра требует токена по контракту.
  final Dio _authDio = appDio;

  @override
  Future<StoriesFeedResult> getStories() async {
    try {
      final response = await _publicDio.get('${mainUrl}stories');
      // ВНИМАНИЕ: это единственная ручка в приложении, отдающая массив верхнего
      // уровня. Привычная проверка `data is! Map` отвергла бы каждый успешный
      // ответ.
      if (response.statusCode != 200 || response.data is! List) {
        storiesLog.warn(
          'getStories unexpected response',
          'status=${response.statusCode}, data=${response.data.runtimeType}',
        );
        return const StoriesFeedFailed();
      }
      return StoriesFeedLoaded(_parseGroups(response.data as List));
    } on DioException catch (e) {
      storiesLog.error('getStories dio error', e.toString(), e);
      return const StoriesFeedFailed();
    } catch (e, st) {
      storiesLog.error('getStories exception', e.toString(), e, st);
      return const StoriesFeedFailed();
    }
  }

  /// Порядок с сервера не трогаем: продавцы с непросмотренными уже идут
  /// первыми, а внутри продавца сториз отсортированы по возрастанию createdAt.
  List<StoryGroupModel> _parseGroups(List raw) {
    final groups = <StoryGroupModel>[];
    for (final item in raw) {
      if (item is! Map) continue;
      try {
        final group = StoryGroupModel.fromJson(Map<String, dynamic>.from(item));
        // Между ответом сервера и открытием просмотрщика сториз может
        // протухнуть — фильтруем и выкидываем опустевшие группы.
        final alive =
            group.stories.where((StoryModel s) => !s.isExpired).toList();
        if (alive.isEmpty) continue;
        groups.add(group.copyWith(stories: alive));
      } catch (e) {
        storiesLog.warn('getStories skipped malformed group', e.toString());
      }
    }
    return groups;
  }

  @override
  Future<MarkStoryViewedResult> markViewed(int storyId) async {
    try {
      final response = await _authDio.post('${mainUrl}stories/$storyId/view');
      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) return const MarkStoryViewedOk();
      storiesLog.warn('markViewed unexpected response', 'status=$status');
      return const MarkStoryViewedFailed();
    } on DioException catch (e) {
      switch (e.response?.statusCode) {
        case 404:
          // Протухла или удалена — для клиента это тот же успех.
          return const MarkStoryViewedGone();
        case 401:
          return const MarkStoryViewedUnauthorized();
      }
      storiesLog.error('markViewed dio error', e.toString(), e);
      return const MarkStoryViewedFailed();
    } catch (e, st) {
      storiesLog.error('markViewed exception', e.toString(), e, st);
      return const MarkStoryViewedFailed();
    }
  }
}
