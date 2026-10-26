import '../../features/catalog/data/models/category_product_model.dart';
import '../../features/live/data/models/live_product_card_model.dart';
import '../../features/product/data/models/product_model.dart';

/// Мост между моделью карточки и моделью детали товара.
///
/// Нужен там, где по карточке надо оптимистично положить товар в корзину:
/// `CartCubit.addCart(product:)` принимает [ProductModel]. Без этого позиция
/// не добавляется в локальный кэш и пользователь не видит отклика до ответа
/// сервера.
///
/// Вынесено из приватного `_toProductModel` в `core/widgets/product_card.dart`,
/// чтобы им мог пользоваться и лайв-шит подарков.
ProductModel productModelFrom(CategoryProductModel c) => ProductModel(
      id: c.id,
      name: c.name,
      price: c.price,
      oldPrice: c.oldPrice,
      photoUrls: c.photoUrls,
      descriptionKz: c.descriptionKz,
      descriptionRu: c.descriptionRu,
      descriptionEn: c.descriptionEn,
      collections: c.collections,
      inStockCount: c.inStockCount,
      isInFavorite: c.isInFavorite,
      plusPrice: c.plusPrice,
      ticketsCount: c.ticketsCount,
      deal: null,
      detailedDescriptionEn: null,
      detailedDescriptionKz: null,
      detailedDescriptionRu: null,
      weightInKg: null,
      product: null,
    );

/// То же для карточки товара из эфира.
///
/// Форма `ProductCard` беднее каталожной, поэтому часть полей заведомо пустая,
/// и это осознанно:
/// * `descriptionKz/Ru/En` — их нет в payload, карточка подписывается по `name`;
/// * `collections` — бейджи «Новинка»/«Скидка» на оптимистичном кадре не
///   покажутся, но приедут с ответом `GET /cart`;
/// * `isInFavorite` — сердечка на закреплённой карточке нет;
/// * `ticketsCount` — бейдж билетов не рисуем;
/// * `inStockCount` — остаток по сокету неизвестен. `null`, а не `0`: ноль
///   означал бы «нет в наличии» и заблокировал бы кнопку у товара, который на
///   самом деле есть. Итоговое решение всё равно за сервером.
///
/// Цены в контракте эфира — `num`, а всё приложение моделирует их `int?`.
/// Округление живёт здесь и только здесь.
ProductModel productModelFromLive(LiveProductCardModel c) => ProductModel(
      id: c.id,
      name: c.name,
      price: c.price?.round(),
      oldPrice: c.oldPrice?.round(),
      plusPrice: c.plusPrice?.round(),
      photoUrls: c.photoUrls,
      descriptionKz: null,
      descriptionRu: null,
      descriptionEn: null,
      collections: null,
      inStockCount: null,
      isInFavorite: null,
      ticketsCount: null,
      deal: null,
      detailedDescriptionEn: null,
      detailedDescriptionKz: null,
      detailedDescriptionRu: null,
      weightInKg: null,
      product: null,
    );
