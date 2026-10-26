import 'package:json_annotation/json_annotation.dart';

part 'review_model.g.dart';

/// Автор отзыва.
///
/// Фамилию бэк намеренно отдаёт только инициалом — чтобы не публиковать
/// фамилии покупателей. Имя может быть `null`, если у пользователя нет профиля.
@JsonSerializable()
class ReviewUserModel {
  final String? firstName;
  final String? lastNameInitial;
  final String? avatarUrl;

  const ReviewUserModel({
    this.firstName,
    this.lastNameInitial,
    this.avatarUrl,
  });

  factory ReviewUserModel.fromJson(Map<String, dynamic> json) =>
      _$ReviewUserModelFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewUserModelToJson(this);
}

/// Отзыв о товаре — `GET /model/:id/reviews`.
///
/// [rating] приходит, но не рисуется: в макете звёзд нет, поле заведено на
/// будущее и может быть `null`.
///
/// Своего отзыва в списке не отличить — бэк не отдаёт ни `isOwn`, ни `userId`,
/// поэтому редактирование и удаление пока не реализуемы.
@JsonSerializable(explicitToJson: true)
class ReviewModel {
  final int id;
  final String? text;
  final int? rating;

  /// ISO-строка. Форматируется через `AppDateFormatter.formatDayMonthYear`.
  final String? createdAt;

  final ReviewUserModel? user;

  const ReviewModel({
    required this.id,
    this.text,
    this.rating,
    this.createdAt,
    this.user,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) =>
      _$ReviewModelFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewModelToJson(this);
}
