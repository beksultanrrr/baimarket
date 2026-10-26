import 'package:bai_market/features/product/data/models/product_model.dart';
import 'package:bai_market/features/product/domain/repositories/product_repository.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/app_dio.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/urls.dart';

class ProductServices implements ProductRepository {
  // Раньше здесь был сырой `Dio()` без заголовка авторизации, из-за чего
  // `isInFavorite` на детали товара не заполнялся никогда, а `hasActivePlus`
  // всегда приходил false. Авторизация у ручки опциональная, поэтому нужен
  // именно optionalAuthDio: appDio без токена вообще не делает запрос.
  final Dio _dio = optionalAuthDio;

  @override
  Future<ProductDetailResult> getProductDetail({required int id}) async {
    try {
      final response = await _dio.get('${mainUrl}model/$id');
      // Статус проверяем ДО парсинга: раньше `fromJson` вызывался первым и
      // падал на теле ошибки, а исключение молча превращалось в null.
      if (response.statusCode != 200 || response.data is! Map) {
        productLog.warn(
          'getProductDetail unexpected response',
          'status=${response.statusCode}, data=${response.data.runtimeType}',
        );
        return const ProductDetailFailed();
      }
      return ProductDetailLoaded(
        ProductModel.fromJson(Map<String, dynamic>.from(response.data as Map)),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        productLog.warn('getProductDetail 404', 'model=$id');
        return const ProductDetailNotFound();
      }
      productLog.error('getProductDetail dio error', e.toString(), e);
      return const ProductDetailFailed();
    } catch (e, st) {
      productLog.error('getProductDetail exception', e.toString(), e, st);
      return const ProductDetailFailed();
    }
  }
}
