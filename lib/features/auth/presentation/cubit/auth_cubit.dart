import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/push/push_token_sync.dart';
import '../../../../core/secure_token_storage.dart';
import '../../../../core/services/app_logger.dart';
import '../../data/datasources/auth_services.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthServices(),
      super(AuthInitial());

  Future<void> sendOtp({required String phoneNumber}) async {
    authLog.step('sendOtp() called', 'phone=$phoneNumber');
    emit(AuthLoading());
    try {
      bool otp = await _authRepository.sendOtp(phoneNumber: phoneNumber);
      if (otp) {
        authLog.state('emit CodeSended');
        emit(CodeSended());
      } else {
        authLog.warn('emit AuthError — sendOtp returned false');
        emit(AuthError(message: 'OTP sending failed'));
      }
    } catch (e, st) {
      authLog.error('sendOtp exception', e.toString(), e, st);
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> verifyOtp({
    required String phoneNumber,
    required String code,
  }) async {
    authLog.step('verifyOtp() called', 'phone=$phoneNumber, code=$code');
    emit(AuthLoading());
    try {
      bool otp = await _authRepository.verifyOtp(
        phoneNumber: phoneNumber,
        code: code,
      );
      if (otp) {
        authLog.state('emit CodeVerified');
        // Единственное место, которое достоверно знает «логин удался».
        // force: true обязателен — токен устройства при смене пользователя не
        // меняется, и кэш «уже отправляли» подавил бы перепривязку к новому
        // userId. Без await: переход на /main ждать этого не должен.
        unawaited(PushTokenSync.onLogin());
        emit(CodeVerified());
      } else {
        authLog.warn('emit AuthError — verifyOtp returned false');
        emit(AuthError(message: 'OTP verification failed'));
      }
    } catch (e, st) {
      authLog.error('verifyOtp exception', e.toString(), e, st);
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> checkAuth() async {
    final token = await getAuthToken();
    authLog.step('checkAuth()', 'hasToken=${token != null}');
    if (token != null) {
      emit(CodeVerified());
    } else {
      emit(AuthInitial());
    }
  }

  Future<void> logOut() async {
    authLog.step('logOut() — revoking refresh token');
    // Сначала отзыв на сервере, потом стирание: после очистки хранилища
    // отзывать будет нечем, и refresh-токен прожил бы на бэкенде все 90 дней.
    // Ошибки глушатся внутри — выход не должен зависеть от сети.
    await revokeRefreshToken();
    // Именно clearTokens: одного access-токена мало, оставленный refresh
    // позволил бы восстановить сессию.
    await clearTokens();
    emit(AuthInitial());
  }
}
