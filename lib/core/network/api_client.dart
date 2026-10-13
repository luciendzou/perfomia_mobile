import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../storage/token_storage.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  static Future<void> Function()? onUnauthorized;

  ApiClient({
    http.Client? client,
    TokenStorage? tokenStorage,
    String? accessToken,
  }) : _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _accessToken = accessToken;

  final http.Client _client;
  final TokenStorage _tokenStorage;
  final String? _accessToken;

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _send(() async {
      return _client.post(
        _uri(path),
        headers: await _headers(),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      );
    });
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    required String fileField,
    required String filePath,
  }) async {
    final token = _accessToken ?? await _tokenStorage.readToken();
    final request = http.MultipartRequest('POST', _uri(path))
      ..headers['Accept'] = 'application/json'
      ..fields.addAll(fields)
      ..files.add(await http.MultipartFile.fromPath(fileField, filePath));
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    final response = await _send(
      () async => http.Response.fromStream(await request.send()),
    );
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> postMultipartFiles(
    String path, {
    required Map<String, String> fields,
    required String fileField,
    required List<String> filePaths,
  }) async {
    final token = _accessToken ?? await _tokenStorage.readToken();
    final request = http.MultipartRequest('POST', _uri(path))
      ..headers['Accept'] = 'application/json'
      ..fields.addAll(fields);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    for (final filePath in filePaths) {
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    }
    final response = await _send(
      () async => http.Response.fromStream(await request.send()),
    );
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> get(String path) async {
    final response = await _send(
      () async => _client.get(_uri(path), headers: await _headers()),
    );
    return _decodeMap(response);
  }

  Future<List<int>> getBytes(String path) async {
    final response = await _send(
      () async => _client.get(_uri(path), headers: await _headers()),
    );
    return response.bodyBytes;
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _send(() async {
      return _client.put(
        _uri(path),
        headers: await _headers(),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      );
    });
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _send(() async {
      return _client.patch(
        _uri(path),
        headers: await _headers(),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      );
    });
    return _decodeMap(response);
  }

  Future<void> delete(String path, {Map<String, dynamic>? body}) async {
    await _send(
      () async => _client.delete(
        _uri(path),
        headers: await _headers(),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Uri _uri(String path) => Uri.parse(
    '${AppConfig.apiBaseUrl}${path.startsWith('/') ? path : '/$path'}',
  );

  Future<Map<String, String>> _headers() async {
    final token = _accessToken ?? await _tokenStorage.readToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }

      if (response.statusCode == 401 || response.statusCode == 419) {
        await _tokenStorage.clear();
        await onUnauthorized?.call();
      }

      final payload = _tryDecode(response.body);
      final message =
          payload?['message']?.toString() ?? 'Une erreur est survenue.';
      throw ApiException(
        _localizeApiMessage(message),
        statusCode: response.statusCode,
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'Impossible de joindre le serveur. Vérifiez votre connexion.',
      );
    } on Exception {
      throw const ApiException(
        'Impossible de joindre le serveur. Vérifiez votre connexion.',
      );
    }
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    final payload = _tryDecode(response.body);
    if (payload == null) throw const ApiException('Réponse API invalide.');
    return payload;
  }

  Map<String, dynamic>? _tryDecode(String body) {
    if (body.isEmpty) return null;
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  String _localizeApiMessage(String message) {
    const exact = <String, String>{
      'Unauthenticated.': 'Votre session a expiré. Veuillez vous reconnecter.',
      'Unauthorized': 'Vous n\'êtes pas autorisé à effectuer cette action.',
      'Forbidden': 'Vous n\'êtes pas autorisé à effectuer cette action.',
      'The given data was invalid.': 'Certaines données sont invalides.',
      'Validation failed': 'La validation des données a échoué.',
      'Not Found': 'La ressource demandée est introuvable.',
      'Server Error': 'Le serveur a rencontré une erreur.',
      'Network Error':
          'Impossible de joindre le serveur. Vérifiez votre connexion.',
    };
    return exact[message] ??
        message
            .replaceAll(
              'The selected value is invalid.',
              'La valeur sélectionnée est invalide.',
            )
            .replaceAll('This field is required.', 'Ce champ est obligatoire.')
            .replaceAll(
              'must be a valid email address',
              'doit être une adresse e-mail valide',
            );
  }
}
