import 'package:json_annotation/json_annotation.dart';

import '../../../seller/data/models/seller_model.dart';
import 'story_model.dart';

part 'story_group_model.g.dart';

/// Группа сториз одного продавца — один кружок в ленте.
///
/// Продавец переиспользует [SellerModel]: `{id, firstName, lastName,
/// avatarUrl}` — строгое подмножество её полей, всё кроме `id` там уже
/// nullable, и `displayName` тоже готов.
@JsonSerializable(explicitToJson: true)
class StoryGroupModel {
  final SellerModel seller;

  /// Флаг с сервера. В UI не используем напрямую: после локальной отметки
  /// просмотра он устаревает, поэтому «есть ли непросмотренные» состояние
  /// считает само.
  @JsonKey(defaultValue: false)
  final bool hasUnviewed;

  @JsonKey(defaultValue: <StoryModel>[])
  final List<StoryModel> stories;

  const StoryGroupModel({
    required this.seller,
    this.hasUnviewed = false,
    this.stories = const [],
  });

  StoryGroupModel copyWith({
    SellerModel? seller,
    bool? hasUnviewed,
    List<StoryModel>? stories,
  }) {
    return StoryGroupModel(
      seller: seller ?? this.seller,
      hasUnviewed: hasUnviewed ?? this.hasUnviewed,
      stories: stories ?? this.stories,
    );
  }

  factory StoryGroupModel.fromJson(Map<String, dynamic> json) =>
      _$StoryGroupModelFromJson(json);
  Map<String, dynamic> toJson() => _$StoryGroupModelToJson(this);
}
