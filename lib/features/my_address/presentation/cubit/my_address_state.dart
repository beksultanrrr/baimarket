part of 'my_address_cubit.dart';

abstract class MyAddressState {}

class MyAddressInitial extends MyAddressState {}

class MyAddressLoading extends MyAddressState {}

class MyAddressLoaded extends MyAddressState {
  final List<UserAddressModel> addresses;
  MyAddressLoaded(this.addresses);
}

/// Что именно не удалось. Готовый текст собирает UI — у кубита нет
/// `BuildContext`, а значит и доступа к локализациям.
enum MyAddressErrorKind { load, add, delete }

class MyAddressError extends MyAddressState {
  final MyAddressErrorKind kind;

  /// Текст от сервера, если он был (например 400 по индексу). UI может
  /// показать его вместо общей фразы по [kind] — там подробностей нет.
  final String? message;

  MyAddressError(this.kind, {this.message});
}
