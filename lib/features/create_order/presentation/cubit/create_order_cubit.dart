import 'package:bai_market/core/services/order_logger.dart';
import 'package:bai_market/features/create_order/data/datasources/create_order_services.dart';
import 'package:bai_market/features/create_order/domain/repositories/create_order_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'create_order_state.dart';

class CreateOrderCubit extends Cubit<CreateOrderState> {
  final CreateOrderRepository _createOrderRepository;
  CreateOrderCubit({CreateOrderRepository? createOrderRepository})
    : _createOrderRepository = createOrderRepository ?? CreateOrderServices(),
      super(CreateOrderInitial());

  void reset() {
    orderLog.state('reset() → CreateOrderInitial');
    emit(CreateOrderInitial());
  }

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
    orderLog.step(
      'createOrder() called',
      'cartId=$cartId, fullName="$fullName", phone="$phoneNumber", '
          'selfPick=$selfPick, postalCode="$postalCode", cityId=$cityId, '
          'deliveryAddress="$deliveryAddress", filialId=$filialId, '
          'pickupUrl=$pickupUrl, paymentTypeSlug=$paymentTypeSlug',
    );
    orderLog.state('emit OrderCreating');
    emit(OrderCreating());
    try {
      final res = await _createOrderRepository.createOrder(
        cartId: cartId,
        fullName: fullName,
        phoneNumber: phoneNumber,
        selfPick: selfPick,
        postalCode: postalCode,
        cityId: cityId,
        deliveryAddress: deliveryAddress,
        comment: comment,
        pickupUrl: pickupUrl,
        selfPickDate: selfPickDate,
        filialId: filialId,
        paymentTypeSlug: paymentTypeSlug,
      );
      if (res != null) {
        orderLog.state(
          'emit OrderCreated',
          'orderId=${res.orderId}, redirectUrl="${res.redirectUrl}"',
        );
        emit(OrderCreated(
          orderId: res.orderId,
          redirectUrl: res.redirectUrl,
        ));
      } else {
        orderLog.state('emit OrderCreateError (res == null)');
        emit(const OrderCreateError());
      }
      return res;
    } on OrderCreationException catch (e, st) {
      orderLog.error('OrderCreationException → emit error', e.message, e, st);
      emit(OrderCreateError(message: e.message));
      return null;
    } catch (e, st) {
      orderLog.error('createOrder cubit-level exception', e.toString(), e, st);
      emit(const OrderCreateError());
      return null;
    }
  }
}
