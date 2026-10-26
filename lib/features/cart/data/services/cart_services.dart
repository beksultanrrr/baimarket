import 'dart:convert';

import 'package:bai_market/features/cart/data/models/cart_model.dart';
import 'package:bai_market/features/cart/domain/repositories/cart_repository.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/app_dio.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/urls.dart';
import '../models/cart_change_model.dart';

class CartServices implements CartRepository {
  final Dio _dio = appDio;

  @override
  Future<CartFetch> getCart() async {
    try {
      final response = await _dio.get('${mainUrl}cart');
      if (response.statusCode != 200) {
        cartLog.warn('getCart unexpected status', '${response.statusCode}');
        return const CartFetchFailed(null);
      }
      final (cart, changes) = _parseEnvelope(response.data);
      if (cart == null) return const CartFetchNoCart();
      return CartFetchOk(cart, changes);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      // 404 — «корзины нет». Это нормальное состояние: после очистки и после
      // оформления заказа. Показывать надо пустой экран, а не ошибку.
      if (code == 404) return const CartFetchNoCart();
      if (code == 401) return const CartFetchUnauthorized();
      cartLog.warn('getCart failed', 'status=$code');
      return CartFetchFailed(_extractServerMessage(e.response?.data));
    } catch (e, st) {
      cartLog.error('getCart exception', e.toString(), e, st);
      return const CartFetchFailed(null);
    }
  }

  @override
  Future<CartWrite> addToCart({required int modelId, int quantity = 1}) async {
    // Меньше 1 запрещено валидацией бэка — гарантируем, что такой запрос
    // вообще не уйдёт.
    assert(quantity >= 1, 'quantity must be >= 1, got $quantity');
    if (quantity < 1) {
      cartLog.error('addToCart called with quantity=$quantity — blocked');
      return const CartWriteFailed();
    }
    try {
      final response = await _dio.post(
        '${mainUrl}cart',
        data: jsonEncode({'modelId': modelId, 'quantity': quantity}),
      );
      final code = response.statusCode ?? 0;
      if (code < 200 || code >= 300) {
        cartLog.warn('addToCart unexpected status', '$code');
        return const CartWriteFailed();
      }
      final (cart, changes) = _parseEnvelope(response.data);
      cartLog.api('addToCart model=$modelId qty=$quantity', 'status=$code');
      return CartWriteOk(cart, changes);
    } on DioException catch (e) {
      return _writeError(e, 'addToCart');
    } catch (e, st) {
      cartLog.error('addToCart exception', e.toString(), e, st);
      return const CartWriteFailed();
    }
  }

  @override
  Future<CartWrite> deleteCartItem({required int cartItemId}) async {
    try {
      final response = await _dio.delete('${mainUrl}cartitem/$cartItemId');
      final code = response.statusCode ?? 0;
      if (code < 200 || code >= 300) {
        cartLog.warn('deleteCartItem unexpected status', '$code');
        return const CartWriteFailed();
      }
      final (cart, changes) = _parseEnvelope(response.data);
      cartLog.api('deleteCartItem id=$cartItemId', 'status=$code');
      return CartWriteOk(cart, changes);
    } on DioException catch (e) {
      // Позиции уже нет — цель достигнута, вызывающий просто перечитает корзину.
      if (e.response?.statusCode == 404) {
        cartLog.warn('deleteCartItem 404 — already gone', 'id=$cartItemId');
        return const CartWriteOk(null, []);
      }
      return _writeError(e, 'deleteCartItem');
    } catch (e, st) {
      cartLog.error('deleteCartItem exception', e.toString(), e, st);
      return const CartWriteFailed();
    }
  }

  @override
  Future<CartWrite> clearCart() async {
    try {
      final response = await _dio.delete('${mainUrl}cart');
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        cartLog.api('clearCart', 'status=$code');
        return const CartWriteNoCart();
      }
      cartLog.warn('clearCart unexpected status', '$code');
      return const CartWriteFailed();
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      // 404 — корзины уже нет, то есть цель достигнута.
      if (code == 404) {
        cartLog.api('clearCart 404 — already empty');
        return const CartWriteNoCart();
      }
      if (code == 401) return const CartWriteUnauthorized();
      cartLog.warn('clearCart failed', 'status=$code');
      return const CartWriteFailed();
    } catch (e, st) {
      cartLog.error('clearCart exception', e.toString(), e, st);
      return const CartWriteFailed();
    }
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  CartWrite _writeError(DioException e, String op) {
    final code = e.response?.statusCode;
    if (code == 401) return const CartWriteUnauthorized();
    final message = _extractServerMessage(e.response?.data);
    cartLog.warn('$op failed', 'status=$code, body=${e.response?.data}');
    if (message != null && (code == 400 || code == 404)) {
      return CartWriteRejected(message, code);
    }
    return const CartWriteFailed();
  }

  /// Принимает и `{cart: {...}, changes: [...]}`, и «голую» корзину:
  /// документирована форма только у `GET /cart`, ответы `POST /cart` и
  /// `DELETE /cartitem/:id` описаны как «полная актуальная корзина».
  (CartModel?, List<CartChangeModel>) _parseEnvelope(dynamic data) {
    if (data is! Map) return (null, const []);
    final map = Map<String, dynamic>.from(data);

    final rawChanges = map['changes'];
    final changes = <CartChangeModel>[];
    if (rawChanges is List && rawChanges.isNotEmpty) {
      // Имена полей внутри `changes` в контракте описаны прозой — логируем
      // сырой массив, чтобы уточнить их по стенду.
      cartLog.api('cart changes raw', rawChanges.toString());
      for (final c in rawChanges) {
        if (c is Map) {
          changes.add(CartChangeModel.fromJson(Map<String, dynamic>.from(c)));
        }
      }
    }

    final rawCart = map.containsKey('cart') ? map['cart'] : map;
    if (rawCart is! Map) return (null, changes);
    try {
      return (
        CartModel.fromJson(Map<String, dynamic>.from(rawCart)),
        changes,
      );
    } catch (e) {
      cartLog.error('cart parse failed', e.toString());
      return (null, changes);
    }
  }

  /// Достаёт сообщение сервера. Учитывает списочную форму, которую отдаёт
  /// валидация: `{"message": ["quantity must not be less than 1"]}`.
  String? _extractServerMessage(dynamic data) {
    if (data is! Map) return null;
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) return message;
    if (message is List) {
      final parts = message.whereType<String>().where((s) => s.trim().isNotEmpty);
      if (parts.isNotEmpty) return parts.join(', ');
    }
    final error = data['error'];
    if (error is String && error.trim().isNotEmpty) return error;
    return null;
  }
}
