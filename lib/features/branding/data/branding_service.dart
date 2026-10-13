import '../../../core/network/api_client.dart';

class BrandingService {
  BrandingService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<CompanyBranding?> fetch() async {
    final payload = await _apiClient.get('/company-logo');
    final value = payload['data'];
    if (value is! Map<String, dynamic>) return null;
    return CompanyBranding(
      companyName: value['company_name']?.toString(),
      logoUrl: value['logo_url']?.toString(),
    );
  }
}

class CompanyBranding {
  const CompanyBranding({this.companyName, this.logoUrl});

  final String? companyName;
  final String? logoUrl;
}
