import '../models/commerce_models.dart';
import 'api_client.dart';

class CommerceApi {
  final _dio = ApiClient().dio;

  // Unwraps CommerceCustomerResponseData<T> envelope: {success, message, data}
  Map<String, dynamic> _unwrap(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      if (data is Map<String, dynamic>) return data;
    }
    return {};
  }

  Future<List<CategorySummary>> getCategories({bool featuredOnly = false}) async {
    final response = await _dio.get('/api/v1/commerce/categories', queryParameters: {
      if (featuredOnly) 'featuredOnly': true,
    });
    final items = response.data as List<dynamic>? ?? [];
    return items.map((e) => CategorySummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ProductSummary>> getProducts({
    String? category,
    String? search,
    String? sort,
    int page = 0,
    int limit = 20,
  }) async {
    final response = await _dio.get('/api/v1/commerce/products', queryParameters: {
      if (category != null) 'category': category,
      if (search != null) 'search': search,
      if (sort != null) 'sort': sort,
      'page': page,
      'size': limit,
    });
    // Backend returns Spring Page: {content: [...], totalElements: N, ...}
    final data = response.data;
    final items = (data is Map ? data['content'] : data) as List<dynamic>? ?? [];
    return items.map((e) => ProductSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ProductSummary>> searchProducts({
    required String q,
    List<String>? categoryIds,
    int? priceMin,
    int? priceMax,
    bool? inStock,
    String sort = 'relevance',
    int page = 0,
    int size = 20,
  }) async {
    final params = <String, dynamic>{
      'q': q,
      'sort': sort,
      'page': page,
      'size': size,
    };
    if (categoryIds != null) {
      for (final id in categoryIds) {
        params['categoryIds'] = id;
      }
    }
    if (priceMin != null) params['priceMin'] = priceMin;
    if (priceMax != null) params['priceMax'] = priceMax;
    if (inStock == true) params['inStock'] = 'true';

    final response = await _dio.get('/api/v1/commerce/products/search', queryParameters: params);
    final data = response.data;
    // Search endpoint returns { hits: [...], total, page, ... }
    final items = (data is Map ? data['hits'] : data) as List<dynamic>? ?? [];
    return items.map((e) {
      final hit = e as Map<String, dynamic>;
      // Search hits have price as plain int (cents) and thumbnailUrl instead of mainImageSet
      return ProductSummary(
        id: hit['id']?.toString() ?? '',
        name: hit['name'] as String? ?? '',
        slug: hit['slug'] as String? ?? '',
        imageUrl: hit['thumbnailUrl'] as String?,
        price: ((hit['price'] as num?) ?? 0) / 100.0,
        compareAtPrice: hit['compareAtPrice'] != null
            ? ((hit['compareAtPrice'] as num) / 100.0)
            : null,
        inStock: hit['inStock'] as bool? ?? true,
        rating: (hit['rating'] as num?)?.toDouble(),
      );
    }).toList();
  }

  Future<ProductDetail> getProduct(String slug) async {
    final response = await _dio.get('/api/v1/commerce/products/$slug');
    return ProductDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Cart> getCart() async {
    final response = await _dio.get('/api/v1/commerce/cart/current');
    return Cart.fromJson(_unwrap(response.data));
  }

  Future<Cart> addToCart(String? variantId, int qty, {String? productId}) async {
    final response = await _dio.post('/api/v1/commerce/cart/items', data: {
      if (productId != null && productId.isNotEmpty) 'productId': productId,
      if (variantId != null && variantId.isNotEmpty) 'variantId': variantId,
      'quantity': qty,
    });
    return Cart.fromJson(_unwrap(response.data));
  }

  Future<Cart> updateCartItem(String entryId, int qty) async {
    final response = await _dio.patch('/api/v1/commerce/cart/items/$entryId', data: {
      'quantity': qty,
    });
    return Cart.fromJson(_unwrap(response.data));
  }

  Future<Cart> removeCartItem(String entryId) async {
    final response = await _dio.delete('/api/v1/commerce/cart/items/$entryId');
    return Cart.fromJson(_unwrap(response.data));
  }

  Future<Cart> applyDiscount(String code) async {
    final response = await _dio.post('/api/v1/commerce/cart/discounts', data: {'code': code});
    return Cart.fromJson(_unwrap(response.data));
  }

  Future<Cart> removeDiscount(String code) async {
    final response = await _dio.delete('/api/v1/commerce/cart/discounts/$code');
    return Cart.fromJson(_unwrap(response.data));
  }

  Future<List<DeliveryShippingSplit>> getDeliveryShippingOptions() async {
    final response = await _dio.get('/api/v1/commerce/cart/delivery-shipping-options');
    final data = response.data;
    final items = (data is Map ? data['data'] : data) as List<dynamic>? ?? [];
    return items
        .map((e) => DeliveryShippingSplit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Cart> setDeliveryShipping(String deliveryId, {
    required String provider,
    required String serviceCode,
    required String name,
    String? company,
    required int priceInCents,
    required int deliveryDays,
    String? providerData,
    bool insuranceIncluded = true,
  }) async {
    final response = await _dio.patch(
      '/api/v1/commerce/cart/deliveries/$deliveryId/shipping',
      data: {
        'provider': provider,
        'serviceCode': serviceCode,
        'name': name,
        'company': company,
        'priceInCents': priceInCents,
        'deliveryDays': deliveryDays,
        'providerData': providerData,
        'insuranceIncluded': insuranceIncluded,
      },
    );
    return Cart.fromJson(_unwrap(response.data));
  }

  Future<Cart> selectShippingMethod(String methodId) async {
    final response = await _dio.post('/api/v1/commerce/cart/shipping-method', data: {'shippingMethodId': methodId});
    return Cart.fromJson(_unwrap(response.data));
  }

  Future<Cart> selectPaymentMethod(String methodId) async {
    final response = await _dio.post('/api/v1/commerce/cart/payment-method', data: {'paymentMethodId': methodId});
    return Cart.fromJson(_unwrap(response.data));
  }

  Future<Order> placeOrder() async {
    final response = await _dio.post('/api/v1/commerce/cart/checkout/place-order');
    return Order.fromJson(_unwrap(response.data));
  }

  Future<CustomerOrder> getOrder(String id) async {
    // Backend has no single-order GET; fetch first page and find by id.
    final response = await _dio.get('/api/v1/commerce/customer/orders',
        queryParameters: {'page': 0, 'size': 50});
    final data = response.data;
    final items = (data is Map ? data['content'] : data) as List<dynamic>? ?? [];
    final match = items
        .map((e) => CustomerOrder.fromJson(e as Map<String, dynamic>))
        .where((o) => o.id == id)
        .firstOrNull;
    return match ?? CustomerOrder.fromJson({'id': id});
  }

  Future<List<CustomerAddress>> listAddresses() async {
    final response = await _dio.get('/api/v1/commerce/customer/addresses');
    final raw = response.data;
    // Unwrap {success, data} envelope if present, same as web's request() helper
    final items = (raw is Map && raw.containsKey('data') ? raw['data'] : raw) as List<dynamic>? ?? [];
    return items.map((e) => CustomerAddress.fromJson(e as Map<String, dynamic>)).toList();
  }
}
