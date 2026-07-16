part of 'create_order_cubit.dart';

abstract class CreateOrderState extends Equatable {
  const CreateOrderState();

  @override
  List<Object> get props => [];
}

class CreateOrderInitial extends CreateOrderState {}

class OrderCreating extends CreateOrderState {}

class OrderCreated extends CreateOrderState {
  final int? orderId;
  final String? redirectUrl;
  const OrderCreated({this.orderId, this.redirectUrl});

  @override
  List<Object> get props => [orderId ?? -1, redirectUrl ?? ''];
}

class OrderCreateError extends CreateOrderState {
  final String? message;
  const OrderCreateError({this.message});

  @override
  List<Object> get props => [message ?? ''];
}
