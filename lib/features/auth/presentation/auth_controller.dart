import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../core/network/dio_provider.dart';
import '../../transactions/transaction_controller.dart';
import '../../wallets/presentation/wallet_screen.dart';
import '../../../shared/widgets/wallet_summary_widget.dart';
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
    this.isInitializing = true, // true khi app mới mở, chờ tryAutoLogin xong
  });

  final AppUser? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final bool isInitializing; // Giữ splash/loading cho đến khi auto-login xong

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    bool? isInitializing,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isInitializing: isInitializing ?? this.isInitializing,
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
    try {
      final token =
          await _ref.read(secureStorageServiceProvider).readToken();
      if (token == null || token.isEmpty) {
        // Không có token — kết thúc khởi tạo, hiện login
        state = state.copyWith(isInitializing: false);
        return;
      }

      final userId =
          await _ref.read(secureStorageServiceProvider).readUserId();
      if (userId == null || userId.isEmpty || userId == 'cached') {
        state = state.copyWith(isInitializing: false);
        return;
      }

      // Set user trước
      state = state.copyWith(
        isAuthenticated: true,
        user: AppUser(
          id: userId,
          name: 'User',
          email: 'email@user.app',
          role: 'user',
        ),
        isInitializing: false, // chưa xong, vẫn đang load transactions
      );

      // Sau khi user đã set → load lịch sử giao dịch từ storage
      await _ref.read(transactionsProvider.notifier).loadForCurrentUser();

    } catch (e) {
      debugPrint('Auto-login error: $e');
    } finally {
      // Dù thành công hay thất bại đều kết thúc initializing
      state = state.copyWith(isInitializing: false);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final (token, user) = await _ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);

      await _ref.read(secureStorageServiceProvider).saveToken(token);
      await _ref.read(secureStorageServiceProvider).saveUserId(user.id);

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        isInitializing: false,
      );

      _ref.invalidate(walletsProvider);
      _ref.invalidate(dashboardWalletsProvider);

      // Load lịch sử giao dịch của user này từ local storage
      await _ref.read(transactionsProvider.notifier).loadForCurrentUser();
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
      await _ref.read(secureStorageServiceProvider).saveUserId(user.id);

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        isInitializing: false,
      );

      _ref.invalidate(walletsProvider);
      _ref.invalidate(dashboardWalletsProvider);

      // User mới → storage rỗng, load để reset state về []
      await _ref.read(transactionsProvider.notifier).loadForCurrentUser();
    } catch (e) {
      String errorMsg = 'Đăng ký thất bại.';
      if (e is DioException) {
        if (e.response?.data is Map &&
            e.response?.data['message'] != null) {
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
    // Xóa state giao dịch trong bộ nhớ (KHÔNG xóa storage — giữ lịch sử)
    _ref.read(transactionsProvider.notifier).clearStateOnLogout();

    _ref.invalidate(walletsProvider);
    _ref.invalidate(dashboardWalletsProvider);

    await _ref.read(secureStorageServiceProvider).clearToken();
    try {
      await _ref.read(secureStorageServiceProvider).clearUserId();
    } catch (_) {}

    _ref.read(themeModeProvider.notifier).state = ThemeMode.system;

    state = const AuthState(isInitializing: false);
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