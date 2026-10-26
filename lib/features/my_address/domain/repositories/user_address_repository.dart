import '../../data/models/user_address_model.dart';

abstract class UserAddressRepository {
  Future<List<UserAddressModel>> getAddresses();
  Future<void> addAddress(UserAddressModel address);

  /// Правка сохранённого адреса (`PATCH /user-address/:id`).
  Future<void> updateAddress(int id, UserAddressModel address);
  Future<void> deleteAddress(int id);
}
