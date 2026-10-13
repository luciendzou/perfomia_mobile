import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final Map<String, dynamic> user;
}

class AuthService {
  AuthService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage(),
      _apiClient = apiClient ?? ApiClient(tokenStorage: tokenStorage);

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final payload = await _apiClient.post(
      '/login',
      body: {
        'email': email.trim(),
        'password': password,
        'device_name': AppConfig.deviceName,
      },
    );
    final data = payload['data'];
    if (data is! Map<String, dynamic> ||
        data['token'] is! String ||
        data['user'] is! Map<String, dynamic>) {
      throw const ApiException('Reponse de connexion invalide.');
    }
    final session = AuthSession(
      token: data['token'] as String,
      user: data['user'] as Map<String, dynamic>,
    );
    await _tokenStorage.saveToken(session.token);
    await _tokenStorage.saveUser(session.user);
    return session;
  }

  Future<Map<String, dynamic>> currentUser() async {
    final payload = await _apiClient.get('/me');
    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      await _tokenStorage.saveUser(data);
      return data;
    }
    throw const ApiException('Profil utilisateur invalide.');
  }

  Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String lastName,
    String? phone,
    String? jobTitle,
    String? language,
  }) async {
    final body = <String, dynamic>{
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'phone': phone?.trim(),
      'job_title': jobTitle?.trim(),
    };
    if (language != null) body['language'] = language;
    final payload = await _apiClient.put('/me', body: body);
    final data = payload['data'];
    if (data is Map<String, dynamic>) return data;
    throw const ApiException('Profil utilisateur invalide.');
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String password,
    required String confirmation,
  }) async {
    await _apiClient.put(
      '/me/password',
      body: {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': confirmation,
      },
    );
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/logout');
    } on ApiException {
      // Local cleanup must succeed even when the token is already invalid.
    } finally {
      await _tokenStorage.clear();
    }
  }

  Future<void> registerFcmToken(String token, String platform) async {
    await _apiClient.post(
      '/me/fcm-token',
      body: {'token': token, 'platform': platform},
    );
  }

  Future<void> unregisterFcmToken(String token) async {
    await _apiClient.delete('/me/fcm-token', body: {'token': token});
  }
}
