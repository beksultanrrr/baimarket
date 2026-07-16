import 'package:dio/dio.dart';

import '../../../../core/network/app_dio.dart';
import '../../../../core/urls.dart';

/// Сервис опроса оплаты Kaspi (xpayment).
///
/// Бэк сам узнаёт об оплате по вебхуку — клиент только опрашивает статус
/// заказа и при необходимости берёт новую ссылку (`pay/again`).
class KaspiPaymentService {
  final Dio _dio = appDio;

  /// `GET /order/{id}` → текущий `status` заказа.
  ///
  /// PAYMENT_PENDING — ждём, PROCESSING/PICKUP — оплачено, PAYMENT_FAILED — нет.
  Future<String?> getOrderStatus(int orderId) async {
    try {
      final response = await _dio.get('${mainUrl}order/$orderId');
      final data = response.data;
      if (data is Map) return data['status']?.toString();
      return null;
    } catch (_) {
      return null;
    }
  }

  /// `GET /order/pay/again/{id}` → новый `redirectUrl` Kaspi.
  /// Зовём по истечении ссылки (~15 мин) или после провала оплаты.
  Future<String?> payAgain(int orderId) async {
    try {
      final response = await _dio.get('${mainUrl}order/pay/again/$orderId');
      final data = response.data;
      if (data is Map) return data['redirectUrl']?.toString();
      return null;
    } catch (_) {
      return null;
    }
  }
}
