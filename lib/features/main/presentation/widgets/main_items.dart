import 'package:bai_market/core/app_pallete.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/urls.dart';
import '../../../../core/utils/translation_utils.dart';
import '../../../../core/widgets/show_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../catalog/data/models/category_product_model.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import 'favorite_button.dart';

class MainItems extends StatelessWidget {
  const MainItems({super.key, required this.products});
  final List<CategoryProductModel> products;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GridView.builder(
      shrinkWrap: true,
      itemCount: products.length,
      padding: const EdgeInsets.all(0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        // childAspectRatio: 155 / 242,
        mainAxisExtent: 280,
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 12,
      ),
      physics: NeverScrollableScrollPhysics(),
      itemBuilder:
          (context, index) => CupertinoButton(
            padding: const EdgeInsets.all(0),
            onPressed: () {
              context.push('/product/${products[index].id}');
            },
            child: Container(
              height: double.infinity,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.hardEdge,
                          child: SizedBox(
                            height: 200,
                            width: double.infinity,
                            child: NetworkImageWidget(
                              url:
                                  products[index].photoUrls != null &&
                                          products[index].photoUrls!.isNotEmpty
                                      ? '$imgUrl${products[index].photoUrls![0]}'
                                      : '',
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.all(8),
                              height: 32,
                              width: double.infinity,
                              child: ListView.builder(
                                itemCount:
                                    products[index].collections?.length ?? 0,
                                shrinkWrap: true,
                                scrollDirection: Axis.horizontal,
                                itemBuilder:
                                    (context, index1) => Container(
                                      margin: const EdgeInsets.only(right: 4),
                                      height: 32,
                                      width: 32,
                                      child: NetworkImageWidget(
                                        url:
                                            '$imgUrl${products[index].collections![index1].labelUrl ?? ''}',
                                      ),
                                    ),
                              ),
                            ),
                            const Spacer(),

                            products[index].inStockCount == null ||
                                    products[index].inStockCount! <= 0
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
                                    l10n!.not_in_sale,
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
                                  height: 20,

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
                                    l10n!.in_sale,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white,
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
                            Text(
                              l10n.price(products[index].price.toString()),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            products[index].oldPrice != null
                                ? const SizedBox(width: 4)
                                : const SizedBox(),
                            products[index].oldPrice != null
                                ? Text(
                                  l10n.oldPrice(
                                    products[index].oldPrice.toString(),
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black54,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                )
                                : SizedBox(),
                            const Spacer(),
                            BlocListener<FavoritesCubit, FavoritesState>(
                              listener: (context, state) {
                                if (state is FavoritesAdded ||
                                    state is FavoritesDeleted) {
                                  context.read<ProfileCubit>().getProfileData();
                                }
                              },
                              child: FavoriteButton(
                                productId: products[index].id,
                                isFavorite: products[index].isInFavorite,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          products[index].name ?? l10n.productName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                        ),
                        Text(
                          TranslationUtils.getLocalizedName(
                            context: context,
                            nameKz: products[index].descriptionKz ?? '',
                            nameRu: products[index].descriptionRu ?? '',
                            nameEn: products[index].descriptionEn ?? '',
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
          ),
    );
  }
}
