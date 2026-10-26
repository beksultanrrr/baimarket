import 'package:json_annotation/json_annotation.dart';

import 'seller_raffle_model.dart';

part 'seller_model.g.dart';

/// Продавец (магазин) в контракте пакета 2.
///
/// Одна модель на два ответа — набор ключей отличается, поэтому всё кроме `id`
/// nullable:
/// * `GET /seller` → `{id, firstName, lastName, avatarUrl, bannerUrl,
///   description, isOwn, raffle}`
/// * `GET /model/:id` → `seller` → `{id, firstName, lastName, avatarUrl, isOwn,
///   ordersCount}`
///
/// Не путать с `features/raffle/data/models/seller_model.dart` — там **старый**
/// контракт `GET /raffle` с `nameKz/nameRu/nameEn/slug`. Объединять их нельзя:
/// экран розыгрыша читает локализованные имена через `TranslationUtils`.
@JsonSerializable(explicitToJson: true)
class SellerModel {
  final int id;
  final String? firstName;
  final String? lastName;

  /// Имя файла в MinIO. Полный путь — `$imgUrl$avatarUrl`.
  final String? avatarUrl;

  /// Имя файла в MinIO. Готовая плашка с градиентом и фото внутри — отдельных
  /// полей под цвет/фото нет, карточка магазина рисуется целиком из неё.
  final String? bannerUrl;

  /// Одно поле, без KZ/RU/EN.
  final String? description;

  /// `true` — это сам Bai Market. Фильтрация на стороне клиента: ручка отдаёт
  /// всех активных продавцов, включая его.
  final bool? isOwn;

  /// Активный розыгрыш. `null` — розыгрыш не заведён.
  final SellerRaffleModel? raffle;

  /// Денормализованный счётчик заказов, содержащих товары этого продавца.
  /// Приходит только в `GET /model/:id`.
  final int? ordersCount;

  const SellerModel({
    required this.id,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.bannerUrl,
    this.description,
    this.isOwn,
    this.raffle,
    this.ordersCount,
  });

  /// «Ырысбала Икрамбай» — пустые части отбрасываются.
  String get displayName => [firstName, lastName]
      .whereType<String>()
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .join(' ');

  /// То же, но с переносом строки — так свёрстаны заголовки на баннерах.
  String get displayNameTwoLines => [firstName, lastName]
      .whereType<String>()
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .join('\n');

  factory SellerModel.fromJson(Map<String, dynamic> json) =>
      _$SellerModelFromJson(json);
  Map<String, dynamic> toJson() => _$SellerModelToJson(this);
}
