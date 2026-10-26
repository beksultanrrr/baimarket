import 'package:json_annotation/json_annotation.dart';

part 'collection_badge_model.g.dart';

/// Элемент `collections[]` в ответах по товарам.
///
/// До пакета 2 это была нетипизированная `Map<String, dynamic>`, и код читал
/// её по строковым ключам в шести местах. Пакет 2 добавил `color` и `discount`,
/// поэтому имеет смысл типизировать.
///
/// Все поля nullable: набор ключей отличается между ручками (например, `id`
/// приходит только в `GET /model/:id`), а `color`/`discount` заводятся руками в
/// админке и могут отсутствовать.
@JsonSerializable()
class CollectionBadgeModel {
  final int? id;
  final String? slug;

  /// Имя файла готовой картинки-метки в MinIO. Полный путь — `$imgUrl$labelUrl`.
  final String? labelUrl;

  /// Цвет бейджа в hex, например `"#FA374D"`. Парсить через `colorFromHex`.
  final String? color;

  /// Число процентов на бейдже. **Лейбл, на цену не влияет** — реальная скидка
  /// это `oldPrice` против `price`.
  final int? discount;

  final String? nameKz;
  final String? nameRu;
  final String? nameEn;
  final String? name;

  const CollectionBadgeModel({
    this.id,
    this.slug,
    this.labelUrl,
    this.color,
    this.discount,
    this.nameKz,
    this.nameRu,
    this.nameEn,
    this.name,
  });

  factory CollectionBadgeModel.fromJson(Map<String, dynamic> json) =>
      _$CollectionBadgeModelFromJson(json);
  Map<String, dynamic> toJson() => _$CollectionBadgeModelToJson(this);
}
