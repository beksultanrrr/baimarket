import '../../domain/repositories/user_address_repository.dart';
import '../datasources/user_address_remote_datasource.dart';
import '../models/user_address_model.dart';

class UserAddressRepositoryImpl implements UserAddressRepository {
  final UserAddressRemoteDatasource remoteDatasource;

  UserAddressRepositoryImpl(this.remoteDatasource);

  @override
  Future<List<UserAddressModel>> getAddresses() =>
      remoteDatasource.getAddresses();

  @override
  Future<void> addAddress(UserAddressModel address) =>
      remoteDatasource.addAddress(address);

  @override
  Future<void> updateAddress(int id, UserAddressModel address) =>
      remoteDatasource.updateAddress(id, address);

  @override
  Future<void> deleteAddress(int id) => remoteDatasource.deleteAddress(id);
}
