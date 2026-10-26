import 'package:json_annotation/json_annotation.dart';

part 'live_product_card_model.g.dart';

/// Карточка товара, закреплённого в эфире (`ProductCard` в контракте).
///
/// Приходит из двух мест с одной и той же формой:
/// * REST — `LiveStream.pinnedModel` в `GET /live`, `GET /live/:id`,
///   `GET /live/my`;
/// * сокет — `snapshot.pinnedProduct` и событие `product:shown`.
///
/// Полей карточки каталога здесь **нет**: ни описаний, ни `inStockCount`, ни
/// `collections`, ни `isInFavorite`, ни `cartQuantity`. Всё, что нужно сверх
/// этого, добирается отдельным `GET /model/:id` — см. `productModelFromLive`
/// в `core/utils/product_mappers.dart`.
@JsonSerializable()
class LiveProductCardModel {
  /// Это `modelId`: по нему открывается карточка товара и кладётся в корзину.
  final int id;

  final String? name;

  /// Контракт типизирует цены как `num`. Держим их `num?` — так парсинг не
  /// упадёт на дробном значении внутри socket-хендлера, где исключение ловить
  /// уже некому. Округление до `int` происходит ровно в одном месте — на
  /// границе маппинга в `ProductModel`.
  final num? price;
  final num? oldPrice;

  /// Цена по подписке Plus. `null` — строку Plus не показываем.
  final num? plusPrice;

  /// Имена файлов в MinIO, не URL. Полный путь — `$imgUrl$fileName`.
  /// Nullable, как в остальных моделях товара: ключа может не быть вовсе.
  final List<String>? photoUrls;

  const LiveProductCardModel({
    required this.id,
    this.name,
    this.price,
    this.oldPrice,
    this.plusPrice,
    this.photoUrls,
  });

  /// Первое фото или пустая строка — вызывающий сам решает, чем заполнить дыру.
  String get firstPhoto {
    final photos = photoUrls;
    return (photos != null && photos.isNotEmpty) ? photos.first : '';
  }

  factory LiveProductCardModel.fromJson(Map<String, dynamic> json) =>
      _$LiveProductCardModelFromJson(json);
  Map<String, dynamic> toJson() => _$LiveProductCardModelToJson(this);
}
