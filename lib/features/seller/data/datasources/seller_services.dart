import 'package:dio/dio.dart';

import '../../../../core/network/app_dio.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/urls.dart';
import '../../domain/repositories/seller_repository.dart';
import '../models/seller_model.dart';
import '../models/seller_products_response.dart';

class SellerServices implements SellerRepository {
  // optionalAuthDio, а не appDio: обе ручки публичные, но с токеном обогащают
  // ответ (`isInFavorite`, `cartQuantity`). appDio без токена вообще не делает
  // сетевого вызова.
  final Dio _dio = optionalAuthDio;

  @override
  Future<List<SellerModel>> getSellers() async {
    try {
      final response = await _dio.get('${mainUrl}seller');
      if (response.statusCode != 200 || response.data is! List) {
        sellerLog.warn(
          'getSellers unexpected response',
          'status=${response.statusCode}, data=${response.data.runtimeType}',
        );
        return const [];
      }
      final list = (response.data as List)
          .whereType<Map>()
          .map((e) => SellerModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      sellerLog.api('getSellers → ${list.length} sellers');
      return list;
    } catch (e, st) {
      sellerLog.error('getSellers exception', e.toString(), e, st);
      return const [];
    }
  }

  @override
  Future<SellerProductsResult> getSellerProducts({
    required int id,
    required String sort,
    int limit = 20,
    int skip = 0,
  }) async {
    try {
      final response = await _dio.get(
        '${mainUrl}seller/$id/models',
        queryParameters: {'sort': sort, 'limit': limit, 'skip': skip},
      );
      if (response.statusCode != 200 || response.data is! Map) {
        sellerLog.warn(
          'getSellerProducts unexpected response',
          'status=${response.statusCode}, data=${response.data.runtimeType}',
        );
        return const SellerProductsFailed();
      }
      final data = SellerProductsResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      sellerLog.api(
        'getSellerProducts seller=$id sort=$sort skip=$skip',
        '→ ${data.models.length}/${data.total}',
      );
      return SellerProductsLoaded(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        sellerLog.warn('getSellerProducts 404', 'seller=$id');
        return const SellerProductsNotFound();
      }
      sellerLog.error('getSellerProducts dio error', e.toString(), e);
      return const SellerProductsFailed();
    } catch (e, st) {
      sellerLog.error('getSellerProducts exception', e.toString(), e, st);
      return const SellerProductsFailed();
    }
  }
}
