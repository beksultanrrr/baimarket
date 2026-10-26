import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/app_dio.dart';
import '../../../../core/services/order_logger.dart';
import '../../../../core/urls.dart';
import '../../domain/repositories/create_order_repository.dart';
import '../models/delivery_quote.dart';

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

  String _extractServerMessage(
    dynamic data, {
    String fallback = 'Не удалось оформить заказ',
  }) {
    if (data is Map) {
      final m = data['message'];
      if (m is String && m.isNotEmpty) return m;
      final e = data['error'];
      if (e is String && e.isNotEmpty) return e;
    }
    return fallback;
  }

  /// Upsert адреса засчитываем и по 200: `POST /delivery` перезаписывает
  /// существующую запись, и обновление вполне может прийти без 201.
  bool _isOk(int? statusCode) => statusCode == 200 || statusCode == 201;

  @override
  Future<OrderCreationResult?> createOrder({
    required int cartId,
    required String fullName,
    required String phoneNumber,
    required String postalCode,
    required int cityId,
    required DeliveryMethod deliveryMethod,
    required String deliveryAddress,
    required String houseNumber,
    required String comment,
    required String paymentTypeSlug,
  }) async {
    final orderUrl = '${mainUrl}order/new/';
    // `deliveryAddress` — только улица; дом с квартирой одной строкой в
    // `houseNumber`. Город бэк достаёт из `cityId`, отдельно слать не надо.
    final deliveryBody = {
      "cartId": cartId,
      "fullName": fullName,
      "phoneNumber": phoneNumber,
      "postalCode": postalCode,
      "cityId": cityId,
      "deliveryMethod": deliveryMethod.wire,
      "deliveryAddress": deliveryAddress,
      "houseNumber": houseNumber,
      // До Казпочты не доходит — виден только оператору в админке.
      "comment": comment,
    };
    try {
      orderLog.api('POST $deliveryUrl', deliveryBody);
      final response =
          await _dio.post(deliveryUrl, data: jsonEncode(deliveryBody));
      orderLog.api(
        'POST /delivery → ${response.statusCode}',
        response.data,
      );
      if (!_isOk(response.statusCode)) {
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
      if (!_isOk(orderResponse.statusCode)) {
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
      // Суммы берём из заказа: `totalPrice` — только товары, `deliveryPrice`
      // бэк зафиксировал при создании и уже зашил в платёжную ссылку.
      // К оплате = totalPrice + deliveryPrice, на клиенте ничего не считаем.
      final totalPrice =
          order is Map ? (order['totalPrice'] as num?)?.toInt() : null;
      final deliveryPrice =
          order is Map ? (order['deliveryPrice'] as num?)?.toInt() : null;
      final trackingNumber =
          order is Map ? order['trackingNumber'] as String? : null;
      orderLog.info(
        'order created',
        'id=$orderId, totalPrice=$totalPrice, deliveryPrice=$deliveryPrice, '
            'trackingNumber=$trackingNumber, redirectUrl=$url',
      );
      return OrderCreationResult(
        orderId: orderId,
        redirectUrl: url,
        totalPrice: totalPrice,
        deliveryPrice: deliveryPrice,
        trackingNumber: trackingNumber,
      );
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

  @override
  Future<DeliveryQuote?> quoteDelivery(String postalCode, int cityId) async {
    final body = {"postalCode": postalCode, "cityId": cityId};
    try {
      orderLog.api('POST $deliveryQuoteUrl', body);
      final response = await _dio.post(
        deliveryQuoteUrl,
        data: jsonEncode(body),
      );
      orderLog.api(
        'POST /delivery/quote → ${response.statusCode}',
        response.data,
      );
      if (!_isOk(response.statusCode)) {
        orderLog.warn(
          'delivery/quote returned ${response.statusCode}',
          _extractServerMessage(
            response.data,
            fallback: 'Не удалось рассчитать доставку',
          ),
        );
        return null;
      }
      final quote = DeliveryQuote.tryParse(response.data);
      if (quote == null || quote.options.isEmpty) {
        orderLog.warn('delivery/quote: пустой расчёт', response.data);
        return null;
      }
      return quote;
    } on DioException catch (e, st) {
      // Ошибку наружу не бросаем: расчёт доставки не должен ронять чекаут,
      // UI покажет свой текст на `null`. 429 разбирает интерсептор.
      orderLog.error(
        'delivery/quote DioException ${e.response?.statusCode}',
        e.response?.data ?? e.message,
        e,
        st,
      );
      return null;
    } catch (e, st) {
      orderLog.error('quoteDelivery unexpected', e.toString(), e, st);
      return null;
    }
  }
}
