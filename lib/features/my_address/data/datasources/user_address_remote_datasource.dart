import 'package:dio/dio.dart';

import '../models/user_address_model.dart';

/// Ошибка адресной книги с уже разобранным текстом сервера.
///
/// Нужна формам: бэк проверяет индекс строго на 6 цифр и на 400 присылает
/// внятное сообщение — показывать вместо него общее «Ошибка добавления
/// адреса» жалко, покупатель так и не поймёт, что именно чинить.
class UserAddressException implements Exception {
  final String message;
  final int? statusCode;

  const UserAddressException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class UserAddressRemoteDatasource {
  final Dio dio;
  final String baseUrl;

  UserAddressRemoteDatasource(this.dio, this.baseUrl);

  bool _isOk(int? statusCode) => statusCode == 200 || statusCode == 201;

  /// Достаёт текст ошибки из тела ответа. Валидация на бэке кладёт в `message`
  /// либо строку, либо список строк — по одной на каждое непрошедшее поле.
  String _extractServerMessage(dynamic data, {required String fallback}) {
    if (data is Map) {
      final m = data['message'];
      if (m is String && m.isNotEmpty) return m;
      if (m is List && m.isNotEmpty) {
        final parts = m
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty);
        if (parts.isNotEmpty) return parts.join(', ');
      }
      final e = data['error'];
      if (e is String && e.isNotEmpty) return e;
    }
    return fallback;
  }

  UserAddressException _asUserAddressException(
    DioException e,
    String fallback,
  ) {
    return UserAddressException(
      _extractServerMessage(e.response?.data, fallback: fallback),
      statusCode: e.response?.statusCode,
    );
  }

  Future<List<UserAddressModel>> getAddresses() async {
    try {
      final response = await dio.get('${baseUrl}user-address');
      if (_isOk(response.statusCode)) {
        return (response.data as List)
            .map((e) => UserAddressModel.fromJson(e))
            .toList();
      }
      throw UserAddressException(
        _extractServerMessage(
          response.data,
          fallback: 'Не удалось загрузить адреса',
        ),
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _asUserAddressException(e, 'Не удалось загрузить адреса');
    }
  }

  Future<void> addAddress(UserAddressModel address) async {
    try {
      final response = await dio.post(
        '${baseUrl}user-address',
        data: address.toJson(),
      );
      if (!_isOk(response.statusCode)) {
        throw UserAddressException(
          _extractServerMessage(
            response.data,
            fallback: 'Не удалось сохранить адрес',
          ),
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _asUserAddressException(e, 'Не удалось сохранить адрес');
    }
  }

  /// Правка сохранённого адреса: `PATCH /user-address/:id`.
  ///
  /// Нужна старым адресам — у них `houseNumber == null`, а дом лежит внутри
  /// `addressLine`; удалять и заводить заново ради этого не надо.
  Future<void> updateAddress(int id, UserAddressModel address) async {
    try {
      final response = await dio.patch(
        '${baseUrl}user-address/$id',
        data: address.toJson(),
      );
      if (!_isOk(response.statusCode)) {
        throw UserAddressException(
          _extractServerMessage(
            response.data,
            fallback: 'Не удалось сохранить адрес',
          ),
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _asUserAddressException(e, 'Не удалось сохранить адрес');
    }
  }

  Future<void> deleteAddress(int id) async {
    try {
      final response = await dio.delete('${baseUrl}user-address/$id');
      if (!_isOk(response.statusCode)) {
        throw UserAddressException(
          _extractServerMessage(
            response.data,
            fallback: 'Не удалось удалить адрес',
          ),
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _asUserAddressException(e, 'Не удалось удалить адрес');
    }
  }
}
