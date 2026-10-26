import 'package:json_annotation/json_annotation.dart';

import '../../../../core/models/collection_badge_model.dart';
import '../../../seller/data/models/seller_model.dart';

part 'product_model.g.dart';

/// Ответ `GET /model/:id`.
///
/// Новые поля пакета 2 добавлены опциональными: `plusPrice`, `hasActivePlus`,
/// `ticketsCount`, `reviewsCount`, `seller`. Ключ `seller` до этого молча
/// выбрасывался при парсинге.
///
/// `cartQuantity` здесь **нет** — состояние нижней кнопки «Купить» / «В корзине»
/// берётся из `GET /cart` через `CartCubit`.
@JsonSerializable(explicitToJson: true)
class ProductModel {
  final int id;
  final String? name;
  final int? price;
  final int? oldPrice;
  final bool? deal;
  final List<String>? photoUrls;
  final String? descriptionKz;
  final String? descriptionRu;
  final String? descriptionEn;
  final String? detailedDescriptionKz;
  final String? detailedDescriptionRu;
  final String? detailedDescriptionEn;
  final int? inStockCount;
  final double? weightInKg;
  final List<CollectionBadgeModel>? collections;
  final Map<String, dynamic>? product;
  final bool? isInFavorite;

  /// Цена по Plus-подписке. `null` — строку Plus не показывать.
  final int? plusPrice;

  /// Действует ли [plusPrice] для текущего пользователя уже сейчас.
  /// Без токена всегда `false`.
  final bool? hasActivePlus;

  /// Билеты за покупку одной единицы товара.
  final int? ticketsCount;

  /// Количество **видимых** отзывов — для заголовка «28 отзывы». Админ может
  /// скрыть отзыв, не удаляя, и тогда он выпадает и из списка, и из счётчика.
  final int? reviewsCount;

  /// Продавец. Может быть `null`.
  final SellerModel? seller;

  ProductModel({
    required this.id,
    required this.collections,
    required this.deal,
    required this.descriptionEn,
    required this.descriptionKz,
    required this.descriptionRu,
    required this.detailedDescriptionEn,
    required this.detailedDescriptionKz,
    required this.detailedDescriptionRu,
    required this.inStockCount,
    required this.isInFavorite,
    required this.name,
    required this.oldPrice,
    required this.photoUrls,
    required this.price,
    required this.product,
    required this.weightInKg,
    this.plusPrice,
    this.hasActivePlus,
    this.ticketsCount,
    this.reviewsCount,
    this.seller,
  });
  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}
