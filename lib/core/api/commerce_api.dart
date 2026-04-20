import '../models/commerce_models.dart';
import 'api_client.dart';

class CommerceApi {
  final _dio = ApiClient().dio;

  Future<List<ProductSummary>> getProducts({
    String? category,
    String? search,
    String? sort,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get('/api/v1/storefront/products', queryParameters: {
      if (category != null) 'category': category,
      if (search != null) 'search': search,
      if (sort != null) 'sort': sort,
      'page': page,
      'limit': limit,
    });
    final items = response.data['items'] as List<dynamic>? ?? [];
    return items.map((e) => ProductSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProductDetail> getProduct(String slug) async {
    final response = await _dio.get('/api/v1/storefront/products/$slug');
    return ProductDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Cart> getCart() async {
    final response = await _dio.get('/api/v1/commerce/cart');
    return Cart.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Cart> addToCart(String variantId, int qty) async {
    final response = await _dio.post('/api/v1/commerce/cart/items', data: {
      'variantId': variantId,
      'quantity': qty,
    });
    return Cart.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Cart> updateCartItem(String lineId, int qty) async {
    final response = await _dio.put('/api/v1/commerce/cart/items/$lineId', data: {'quantity': qty});
    return Cart.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Cart> removeCartItem(String lineId) async {
    final response = await _dio.delete('/api/v1/commerce/cart/items/$lineId');
    return Cart.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Cart> applyDiscount(String code) async {
    final response = await _dio.post('/api/v1/commerce/cart/discount', data: {'code': code});
    return Cart.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Cart> removeDiscount() async {
    final response = await _dio.delete('/api/v1/commerce/cart/discount');
    return Cart.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ShippingOption>> getShippingOptions(String zipCode) async {
    final response = await _dio.get('/api/v1/commerce/cart/shipping', queryParameters: {'zipCode': zipCode});
    final items = response.data as List<dynamic>? ?? [];
    return items.map((e) => ShippingOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Cart> selectShipping(String optionId) async {
    final response = await _dio.post('/api/v1/commerce/cart/shipping', data: {'optionId': optionId});
    return Cart.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Cart> selectPayment(String method, Map<String, dynamic> data) async {
    final response = await _dio.post('/api/v1/commerce/cart/payment', data: {'method': method, ...data});
    return Cart.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Order> placeOrder() async {
    final response = await _dio.post('/api/v1/commerce/orders');
    return Order.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Order>> getOrders() async {
    final response = await _dio.get('/api/v1/commerce/orders');
    final items = response.data as List<dynamic>? ?? [];
    return items.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Order> getOrder(String id) async {
    final response = await _dio.get('/api/v1/commerce/orders/$id');
    return Order.fromJson(response.data as Map<String, dynamic>);
  }
}
