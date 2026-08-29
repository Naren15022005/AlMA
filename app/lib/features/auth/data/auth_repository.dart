import '../../../core/services/api_service.dart';
import '../../../shared/models/user_model.dart';

class AuthRepository {
  final ApiService _api;
  AuthRepository(this._api);

  Future<Map<String, dynamic>> register({
    required String email,
    required String name,
    required String password,
    String? birthday,
  }) async {
    final res = await _api.post('/auth/register', data: {
      'email': email,
      'name': name,
      'password': password,
      if (birthday != null) 'birthday': birthday,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<void> logout() => _api.post('/auth/logout');

  Future<UserModel> getMe() async {
    final res = await _api.get('/auth/me');
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> updateFcmToken(String token) =>
      _api.post('/auth/fcm-token', data: {'token': token});
}
