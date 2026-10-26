import 'package:bai_market/features/seller/data/models/seller_model.dart';
import 'package:bai_market/features/stories/data/models/story_group_model.dart';
import 'package:bai_market/features/stories/data/models/story_model.dart';
import 'package:bai_market/features/stories/domain/repositories/stories_repository.dart';

StoryModel buildStory({
  required int id,
  bool isViewed = false,
  String mediaType = 'IMAGE',
}) =>
    StoryModel(
      id: id,
      mediaUrl: '$id.png',
      mediaType: mediaType,
      isViewed: isViewed,
    );

StoryGroupModel buildGroup({
  int sellerId = 1,
  required List<StoryModel> stories,
}) =>
    StoryGroupModel(
      seller: SellerModel(id: sellerId, firstName: 'Продавец'),
      hasUnviewed: stories.any((s) => !s.isViewed),
      stories: stories,
    );

class FakeStoriesRepository implements StoriesRepository {
  FakeStoriesRepository({
    this.feedResult = const StoriesFeedLoaded([]),
    this.viewResult = const MarkStoryViewedOk(),
  });

  StoriesFeedResult feedResult;
  MarkStoryViewedResult viewResult;

  final List<int> viewedCalls = [];

  @override
  Future<StoriesFeedResult> getStories() async => feedResult;

  @override
  Future<MarkStoryViewedResult> markViewed(int storyId) async {
    viewedCalls.add(storyId);
    return viewResult;
  }
}
