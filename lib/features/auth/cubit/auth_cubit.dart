import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/storage_service.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  final StorageService _storageService;

  AuthCubit({
    required AuthService authService,
    required StorageService storageService,
  }) : _authService = authService,
       _storageService = storageService,
       super(AuthInitial()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    try {
      emit(AuthLoading());
      final isSignedIn = await _authService.isSignedIn();
      final authData = await _storageService.getAuthData();

      if (isSignedIn && authData != null) {
        emit(
          AuthAuthenticated(token: authData.token, provider: authData.provider),
        );
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      emit(AuthLoading());
      final userData = await _authService.signInWithGoogle();

      if (userData != null && userData.token != null) {
        await _storageService.saveAuthData(userData.token!, userData.provider);
        emit(
          AuthAuthenticated(
            token: userData.token!,
            provider: userData.provider,
          ),
        );
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> loginWithFacebook() async {
    try {
      emit(AuthLoading());
      final userData = await _authService.signInWithFacebook();

      if (userData != null && userData.token != null) {
        await _storageService.saveAuthData(userData.token!, userData.provider);
        emit(
          AuthAuthenticated(
            token: userData.token!,
            provider: userData.provider,
          ),
        );
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    try {
      emit(AuthLoading());
      await _authService.signOut();
      await _storageService.clearAuthData();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  bool get isLoggedIn => state is AuthAuthenticated;
}
