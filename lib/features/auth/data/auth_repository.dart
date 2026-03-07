import 'package:dio/dio.dart';

import '../domain/user.dart';

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<(String, AppUser)> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final token = response.data['token'] as String;
    final user = AppUser.fromJson(
      response.data['user'] as Map<String, dynamic>,
    );
    return (token, user);
  }

  Future<(String, AppUser)> register({
    required String name,
    required String email,
    required String password,
    required String dob,
    required String gender,
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'dateOfBirth': dob,
        'gender': gender,
      },
    );
    final token = response.data['token'] as String;
    final user = AppUser.fromJson(
      response.data['user'] as Map<String, dynamic>,
    );
    return (token, user);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post(
      '/auth/change-password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  Future<void> changeEmail({
    required String newEmail,
    required String password,
  }) async {
    await _dio.post(
      '/auth/change-email',
      data: {'newEmail': newEmail, 'password': password},
    );
  }

  Future<void> resetUserData() async {
    await _dio.post('/auth/reset-data');
  }
}
