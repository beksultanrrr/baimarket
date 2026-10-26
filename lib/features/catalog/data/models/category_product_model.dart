import 'package:json_annotation/json_annotation.dart';

import '../../../../core/models/collection_badge_model.dart';

part 'category_product_model.g.dart';

/// Модель карточки товара. Один тип на все списки: коллекции, каталог, поиск,
/// розыгрыши, витрина магазина, «Еще может подойти».
///
/// Новые поля пакета 2 (`plusPrice`, `ticketsCount`, `cartQuantity`) добавлены
/// как **опциональные** — не все ручки их отдают, и старые места конструирования
/// не должны ломаться.
@JsonSerializable(explicitToJson: true)
class CategoryProductModel {
  final int id;
  final String? name;
  final int? price;
  final int? oldPrice;
  final List<String>? photoUrls;
  final int? inStockCount;
  final String? descriptionKz;
  final String? descriptionRu;
  final String? descriptionEn;
  final List<CollectionBadgeModel>? collections;

  /// Бэк не отдаёт это поле в `GET /model?q=`, поэтому дефолт обязателен —
  /// иначе сгенерированный `as bool` падает на `null`.
  @JsonKey(defaultValue: false)
  final bool isInFavorite;

  /// Цена по Plus-подписке. `null` — строку Plus не показывать.
  final int? plusPrice;

  /// Билеты за покупку ОДНОЙ единицы товара. `null` или `0` — бейдж не
  /// показывать. На checkout билеты считаются по сумме корзины, поэтому итог в
  /// заказе может отличаться — это ожидаемо, бейдж рекламный.
  final int? ticketsCount;

  /// Снимок количества в корзине на момент запроса — **информационное поле,
  /// UI его не читает**. Живая истина это `CartCubit.quantityOf()`, иначе после
  /// тапа по «+» появятся два расходящихся источника.
  final int? cartQuantity;

  CategoryProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.oldPrice,
    required this.photoUrls,
    required this.inStockCount,
    required this.descriptionKz,
    required this.descriptionRu,
    required this.descriptionEn,
    required this.collections,
    required this.isInFavorite,
    this.plusPrice,
    this.ticketsCount,
    this.cartQuantity,
  });
  factory CategoryProductModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryProductModelFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryProductModelToJson(this);
}
