import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:perfomia_mobile/core/network/api_client.dart';
import 'package:perfomia_mobile/features/courriers/data/courrier_service.dart';

class _CourrierClient extends http.BaseClient {
  Uri? lastUri;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUri = request.url;
    final body = jsonEncode({
      'success': true,
      'data': {
        'current_page': 2,
        'last_page': 4,
        'data': [
          {
            'id': 'courrier-1',
            'reference': 'CR-001',
            'subject': 'Document à traiter',
            'status': 'registered',
          },
        ],
      },
    });
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      200,
      headers: const {'content-type': 'application/json'},
    );
  }
}

void main() {
  test('fetchPage decodes pagination and applies courrier filters', () async {
    final client = _CourrierClient();
    final service = CourrierService(
      apiClient: ApiClient(client: client, accessToken: 'test-token'),
    );

    final page = await service.fetchPage(
      search: 'CR-001',
      type: 'incoming',
      status: 'registered',
      userId: 'user-1',
      page: 2,
    );

    expect(page.items, hasLength(1));
    expect(page.items.single['reference'], 'CR-001');
    expect(page.page, 2);
    expect(page.lastPage, 4);
    expect(client.lastUri?.queryParameters['search'], 'CR-001');
    expect(client.lastUri?.queryParameters['type'], 'incoming');
    expect(client.lastUri?.queryParameters['status'], 'registered');
    expect(client.lastUri?.queryParameters['user_id'], 'user-1');
    expect(client.lastUri?.queryParameters['page'], '2');
  });
}
