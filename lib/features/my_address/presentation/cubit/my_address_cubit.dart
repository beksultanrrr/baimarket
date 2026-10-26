import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/user_address_remote_datasource.dart';
import '../../data/models/user_address_model.dart';
import '../../data/repositories/user_address_repository_impl.dart';

part 'my_address_state.dart';

class MyAddressCubit extends Cubit<MyAddressState> {
  final UserAddressRepositoryImpl repository;

  MyAddressCubit(this.repository) : super(MyAddressInitial());

  /// Текст с сервера, если он есть (его уже разобрал датасорс — например 400
  /// по индексу). На всё остальное (сеть, разбор ответа) возвращаем null:
  /// общую фразу подставит UI из своей локализации, чтобы русские литералы
  /// не оседали в presentation-слое.
  String? _serverMessage(Object error) =>
      error is UserAddressException ? error.message : null;

  Future<void> loadAddresses() async {
    emit(MyAddressLoading());
    try {
      final addresses = await repository.getAddresses();
      emit(MyAddressLoaded(addresses));
    } catch (e) {
      emit(
        MyAddressError(
          MyAddressErrorKind.load,
          message: _serverMessage(e),
        ),
      );
    }
  }

  /// Возвращает null при успехе, иначе — текст ошибки для формы: сообщение
  /// сервера, а если его нет — пустую строку (форма покажет свою общую фразу).
  ///
  /// Состояние ошибки тут намеренно НЕ эмитится: сообщение (в том числе 400
  /// по индексу) показывает сама форма, а список адресов под ней от неудачного
  /// сохранения пропадать не должен.
  Future<String?> addAddress(UserAddressModel address) async {
    try {
      await repository.addAddress(address);
      await loadAddresses();
      return null;
    } catch (e) {
      return _serverMessage(e) ?? '';
    }
  }

  /// Правка сохранённого адреса. Про возвращаемое значение — см. [addAddress].
  Future<String?> updateAddress(int id, UserAddressModel address) async {
    try {
      await repository.updateAddress(id, address);
      await loadAddresses();
      return null;
    } catch (e) {
      return _serverMessage(e) ?? '';
    }
  }

  Future<void> deleteAddress(int id) async {
    final previous = state is MyAddressLoaded ? state as MyAddressLoaded : null;
    try {
      await repository.deleteAddress(id);
      await loadAddresses();
    } catch (e) {
      emit(
        MyAddressError(
          MyAddressErrorKind.delete,
          message: _serverMessage(e),
        ),
      );
      // Неудачное удаление не должно опустошать экран: на состоянии ошибки
      // список не рисуется, поэтому сразу возвращаем то, что было.
      if (previous != null) emit(previous);
    }
  }
}
