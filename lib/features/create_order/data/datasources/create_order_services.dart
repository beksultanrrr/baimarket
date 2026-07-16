import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/app_dio.dart';
import '../../../../core/services/order_logger.dart';
import '../../../../core/urls.dart';
import '../../domain/repositories/create_order_repository.dart';

/// Бросаем при предсказуемых ошибках бэка, чтобы донести `message`
/// до UI. На сетевых/неизвестных ошибках просто возвращаем `null`.
class OrderCreationException implements Exception {
  final String message;
  final int? statusCode;
  const OrderCreationException(this.message, {this.statusCode});

  @override
  String toString() =>
      'OrderCreationException(${statusCode ?? '-'}): $message';
}

class CreateOrderServices implements CreateOrderRepository {
  final Dio _dio = appDio;

  String _extractServerMessage(dynamic data) {
    if (data is Map) {
      final m = data['message'];
      if (m is String && m.isNotEmpty) return m;
      final e = data['error'];
      if (e is String && e.isNotEmpty) return e;
    }
    return 'Не удалось оформить заказ';
  }

  @override
  Future<OrderCreationResult?> createOrder({
    required int cartId,
    required String fullName,
    required String phoneNumber,
    required bool selfPick,
    required String postalCode,
    required int cityId,
    required String deliveryAddress,
    required String comment,
    required String? pickupUrl,
    required String? selfPickDate,
    required int? filialId,
    required String paymentTypeSlug,
  }) async {
    final deliveryUrl = '${mainUrl}delivery';
    final orderUrl = '${mainUrl}order/new/';
    final deliveryBody = {
      "cartId": cartId,
      "fullName": fullName,
      "phoneNumber": phoneNumber,
      "selfPick": selfPick,
      "postalCode": postalCode,
      "cityId": cityId,
      "deliveryAddress": deliveryAddress,
      "comment": comment,
      "pickupUrl": pickupUrl,
      "selfPickDate": selfPickDate,
      "filialId": filialId,
    };
    try {
      orderLog.api('POST $deliveryUrl', deliveryBody);
      final response =
          await _dio.post(deliveryUrl, data: jsonEncode(deliveryBody));
      orderLog.api(
        'POST /delivery → ${response.statusCode}',
        response.data,
      );
      if (response.statusCode != 201) {
        final msg = _extractServerMessage(response.data);
        orderLog.warn(
          'delivery returned ${response.statusCode} → throw "$msg"',
        );
        throw OrderCreationException(msg, statusCode: response.statusCode);
      }

      final orderBody = {"paymentTypeSlug": paymentTypeSlug};
      orderLog.api('POST $orderUrl', orderBody);
      final orderResponse = await _dio.post(
        orderUrl,
        data: jsonEncode(orderBody),
      );
      orderLog.api(
        'POST /order/new/ → ${orderResponse.statusCode}',
        orderResponse.data,
      );
      if (orderResponse.statusCode != 201) {
        final msg = _extractServerMessage(orderResponse.data);
        orderLog.warn(
          'order/new returned ${orderResponse.statusCode} → throw "$msg"',
        );
        throw OrderCreationException(
          msg,
          statusCode: orderResponse.statusCode,
        );
      }

      final data = orderResponse.data;
      final url = data is Map ? data['redirectUrl']?.toString() : null;
      final order = data is Map ? data['order'] : null;
      final orderId = order is Map ? (order['id'] as num?)?.toInt() : null;
      orderLog.info('order created', 'id=$orderId, redirectUrl=$url');
      return OrderCreationResult(orderId: orderId, redirectUrl: url);
    } on OrderCreationException {
      rethrow;
    } on DioException catch (e, st) {
      orderLog.error(
        'DioException ${e.response?.statusCode} on ${e.requestOptions.uri}',
        e.response?.data,
        e,
        st,
      );
      // Если это HTTP-ответ с понятным message — пробрасываем выше,
      // чтобы UI показал текст ошибки.
      if (e.response != null) {
        final msg = _extractServerMessage(e.response!.data);
        throw OrderCreationException(msg, statusCode: e.response!.statusCode);
      }
      return null;
    } catch (e, st) {
      orderLog.error('createOrder unexpected', e.toString(), e, st);
      return null;
    }
  }
}
