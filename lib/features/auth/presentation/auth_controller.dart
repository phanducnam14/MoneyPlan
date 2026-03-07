import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../core/network/dio_provider.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../data/auth_repository.dart';
import '../domain/user.dart';

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  final AppUser? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref)..tryAutoLogin();
  },
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState());

  final Ref _ref;

  Future<void> tryAutoLogin() async {
    final token = await _ref.read(secureStorageServiceProvider).readToken();
    if (token != null && token.isNotEmpty) {
      state = state.copyWith(
        isAuthenticated: true,
        user: const AppUser(
          id: 'cached',
          name: 'User',
          email: 'cached@user.app',
          role: 'user',
        ),
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final (token, user) = await _ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      await _ref.read(secureStorageServiceProvider).saveToken(token);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
      );
    } catch (e) {
      String errorMsg = 'Đăng nhập thất bại.';
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          errorMsg = 'Email hoặc mật khẩu không đúng.';
        } else {
          errorMsg =
              'Không thể kết nối tới máy chủ. Vui lòng kiểm tra kết nối mạng và địa chỉ API.';
        }
      } else if (e is Exception) {
        errorMsg = 'Đăng nhập thất bại: ${e.toString()}';
      }
      state = state.copyWith(isLoading: false, error: errorMsg);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String dob,
    required String gender,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final (token, user) = await _ref
          .read(authRepositoryProvider)
          .register(
            name: name,
            email: email,
            password: password,
            dob: dob,
            gender: gender,
          );
      await _ref.read(secureStorageServiceProvider).saveToken(token);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
      );
    } catch (e) {
      String errorMsg = 'Đăng ký thất bại.';
      if (e is DioException) {
        if (e.response?.data is Map && e.response?.data['message'] != null) {
          errorMsg = e.response?.data['message'].toString() ?? errorMsg;
        } else if (e.response?.statusCode == 400) {
          errorMsg =
              'Đăng ký không hợp lệ. Vui lòng kiểm tra thông tin đã nhập.';
        } else if (e.response?.statusCode == 409) {
          errorMsg = 'Email đã được sử dụng.';
        } else if (e.response?.statusCode == 500) {
          errorMsg = 'Lỗi máy chủ. Vui lòng thử lại sau.';
        } else {
          errorMsg = 'Lỗi: ${e.response?.statusCode}';
        }
      } else if (e is Exception) {
        errorMsg = 'Đăng ký thất bại: ${e.toString()}';
      }
      state = state.copyWith(isLoading: false, error: errorMsg);
    }
  }

  Future<void> logout() async {
    await _ref.read(secureStorageServiceProvider).clearToken();
    _ref.read(themeModeProvider.notifier).state = ThemeMode.system;
    state = const AuthState();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _ref
          .read(authRepositoryProvider)
          .changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Cập nhật mật khẩu thất bại: ${e.toString()}',
      );
    }
  }

  Future<void> changeEmail({
    required String newEmail,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _ref
          .read(authRepositoryProvider)
          .changeEmail(newEmail: newEmail, password: password);
      // Update user info with new email
      state = state.copyWith(
        isLoading: false,
        user: state.user?.copyWith(email: newEmail),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Cập nhật email thất bại: ${e.toString()}',
      );
    }
  }

  Future<bool> resetUserData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _ref.read(authRepositoryProvider).resetUserData();
      state = state.copyWith(isLoading: false, error: null);
      return true;
    } catch (e) {
      String errorMsg = 'Reset dữ liệu thất bại.';
      if (e is DioException) {
        errorMsg = 'Lỗi: ${e.response?.statusCode}';
      }
      state = state.copyWith(isLoading: false, error: errorMsg);
      return false;
    }
  }
}
