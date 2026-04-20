import '../models/storefront_models.dart';
import 'api_client.dart';

class StorefrontApi {
  final _dio = ApiClient().dio;

  Future<StorefrontResolveResponse> resolve() async {
    final response = await _dio.get('/api/v1/storefront/resolve');
    return StorefrontResolveResponse.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<StorefrontPage> getPageByType(String pageType) async {
    final response =
        await _dio.get('/api/v1/storefront/pages/type/$pageType');
    return StorefrontPage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StorefrontPage> getPageByPath(String path) async {
    final response = await _dio
        .get('/api/v1/storefront/pages/by-path', queryParameters: {'path': path});
    return StorefrontPage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StorefrontPage> getProductPage(String slug) async {
    final response =
        await _dio.get('/api/v1/storefront/pages/product/$slug');
    return StorefrontPage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StorefrontPage> getCategoryPage(String slug) async {
    final response =
        await _dio.get('/api/v1/storefront/pages/category/$slug');
    return StorefrontPage.fromJson(response.data as Map<String, dynamic>);
  }
}
