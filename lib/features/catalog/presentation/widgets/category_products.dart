import 'package:bai_market/core/widgets/shimmer.dart';
import 'package:bai_market/features/catalog/presentation/cubit/catalog_cubit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_pallete.dart';
import '../../../../core/urls.dart';
import '../../../../core/utils/translation_utils.dart';
import '../../../../core/widgets/show_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/catalog_model.dart';
import '../../data/models/category_product_model.dart';
import '../../../main/presentation/widgets/favorite_button.dart';

class CategoryProducts extends StatefulWidget {
  const CategoryProducts({super.key});

  @override
  State<CategoryProducts> createState() => _CategoryProductsState();
}

class _CategoryProductsState extends State<CategoryProducts> {
  late CatalogCubit cubit = CatalogCubit();
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CatalogCubit, CatalogState>(
      listener: (context, state) {},
      builder: (context, state) {
        if (state is CatalogGot) {
          return ListView.builder(
            padding: const EdgeInsets.all(0),
            shrinkWrap: true,
            itemCount: state.categories.length,
            itemBuilder:
                (context, index) =>
                    _buildCategoryItem(model: state.categories[index]),
            physics: NeverScrollableScrollPhysics(),
          );
        } else {
          return ListView.builder(
            padding: const EdgeInsets.all(0),
            shrinkWrap: true,
            itemCount: 4,
            itemBuilder: (context, index) => _buildSimpleItem(),
            physics: NeverScrollableScrollPhysics(),
          );
        }
      },
    );
  }

  _buildCategoryItem({required CatalogModel model}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            TranslationUtils.getLocalizedDescription(
              context: context,
              descriptionKz: model.nameKz ?? '',
              descriptionRu: model.nameRu ?? '',
              descriptionEn: model.nameEn ?? '',
            ),

            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 192,
          child: ListView.builder(
            itemCount: model.models.length,
            scrollDirection: Axis.horizontal,
            itemBuilder:
                (context, index) => CupertinoButton(
                  padding: const EdgeInsets.all(0),
                  onPressed: () {},
                  child: Container(
                    margin: EdgeInsets.only(
                      left: index == 0 ? 20 : 0,
                      right: index == 2 ? 20 : 8,
                    ),
                    height: 192,
                    width: 120,
                    decoration: BoxDecoration(
                      color: lightGray,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildProduct(product: model.models[index]),
                  ),
                ),
          ),
        ),
      ],
    );
  }

  _buildSimpleItem() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            'Категория',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          height: 186,
          child: ListView.builder(
            itemCount: 3,
            scrollDirection: Axis.horizontal,
            itemBuilder:
                (context, index) => CupertinoButton(
                  padding: const EdgeInsets.all(0),
                  onPressed: () {},
                  child: Container(
                    margin: EdgeInsets.only(
                      left: index == 0 ? 20 : 0,
                      right: index == 2 ? 20 : 8,
                    ),
                    height: 186,
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SimpleShimmer(borderRadius: 12),
                  ),
                ),
          ),
        ),
      ],
    );
  }

  _buildProduct({required CategoryProductModel product}) {
    final l10n = AppLocalizations.of(context)!;
    return CupertinoButton(
      padding: const EdgeInsets.all(0),
      onPressed: () {
        context.push('/product/${product.id}');
      },
      child: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 120,
              width: 120,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.hardEdge,
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      color: lightGray,
                      // child: Text('$imgUrl${product.photoUrls?[0]}'),
                      child: NetworkImageWidget(
                        url:
                            product.photoUrls != null &&
                                    product.photoUrls!.isNotEmpty
                                ? '$imgUrl${product.photoUrls![0]}'
                                : '',
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.all(6),
                        height: 24,
                        width: double.infinity,
                        child: ListView.builder(
                          itemCount: product.collections?.length ?? 0,
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemBuilder:
                              (context, index) => Container(
                                margin: const EdgeInsets.only(right: 4),
                                height: 24,
                                width: 24,
                                child: NetworkImageWidget(
                                  url:
                                      '$imgUrl${product.collections![index].labelUrl ?? ''}',
                                ),
                              ),
                        ),
                      ),
                      const Spacer(),
                      product.inStockCount == null || product.inStockCount! <= 0
                          ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            margin: const EdgeInsets.all(8),
                            height: 18,

                            decoration: BoxDecoration(
                              color: Color(0xFFF73030),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(0),
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Text(
                              l10n.not_in_sale,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                              ),
                            ),
                          )
                          : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            margin: const EdgeInsets.all(8),
                            height: 18,

                            decoration: BoxDecoration(
                              color: seconColor,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(0),
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Text(
                              l10n.in_sale,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                          ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              "${product.price ?? 999} ₸",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child:
                                  product.oldPrice != null
                                      ? Text(
                                        "${product.oldPrice ?? 999} ₸",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black54,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      )
                                      : SizedBox(),
                            ),
                          ],
                        ),
                      ),
                      FavoriteButton(
                        productId: product.id,
                        isFavorite: product.isInFavorite,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.name}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                  ),
                  Text(
                    TranslationUtils.getLocalizedDescription(
                      context: context,
                      descriptionKz: product.descriptionKz ?? 'Описание',
                      descriptionRu: product.descriptionRu ?? 'Описание',
                      descriptionEn: product.descriptionEn ?? 'Описание',
                    ),

                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.black38,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
