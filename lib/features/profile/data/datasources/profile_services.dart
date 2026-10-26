import 'package:bai_market/features/profile/data/models/current_user_model.dart';
import 'package:bai_market/features/profile/data/models/profile_model.dart';
import 'package:bai_market/features/profile/domain/repositories/profile_repository.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/app_dio.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/urls.dart';

class ProfileServices implements ProfileRepository {
  final Dio _dio = appDio;

  @override
  Future<ProfileModel?> getProfileData() async {
    final finalUrl = '${mainUrl}profile/me/summary';
    try {
      final response = await _dio.get(finalUrl);
      if (response.statusCode == 200) {
        return ProfileModel.fromJson(response.data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CurrentUserResult> getCurrentUser() async {
    try {
      final response = await _dio.get('${mainUrl}users/me/profile');
      // Статус проверяем до разбора: на теле ошибки `fromJson` упал бы, и
      // исключение молча превратилось бы в «роли нет».
      if (response.statusCode != 200 || response.data is! Map) {
        profileLog.warn(
          'getCurrentUser unexpected response',
          'status=${response.statusCode}, data=${response.data.runtimeType}',
        );
        return const CurrentUserFailed();
      }
      final user = CurrentUserModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      profileLog.info('роль пользователя', user.role);
      return CurrentUserLoaded(user);
    } on DioException catch (e) {
      // Гостя `appDio` отклоняет локально синтетическим 401, не доходя до
      // сети, — сюда же попадает и просроченный токен.
      if (e.response?.statusCode == 401) {
        return const CurrentUserUnauthorized();
      }
      profileLog.error('getCurrentUser dio error', e.toString(), e);
      return const CurrentUserFailed();
    } catch (e, st) {
      profileLog.error('getCurrentUser exception', e.toString(), e, st);
      return const CurrentUserFailed();
    }
  }
}
