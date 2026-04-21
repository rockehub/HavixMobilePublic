// price.regular / price.compareAt are in centavos (smallest currency unit)
double _centsToDouble(dynamic raw) =>
    raw == null ? 0.0 : (raw as num).toDouble() / 100.0;

// Extract image URLs from imageSets: [{images: [{url}]}]
List<String> _extractImageUrls(dynamic rawImageSets) {
  if (rawImageSets is! List) return [];
  final urls = <String>[];
  for (final set in rawImageSets) {
    if (set is Map) {
      final images = set['images'];
      if (images is List) {
        for (final img in images) {
          final url = img is Map ? img['url'] as String? : null;
          if (url != null && url.isNotEmpty) urls.add(url);
        }
      }
    }
  }
  return urls;
}

String? _firstImageUrl(dynamic rawImageSet) {
  if (rawImageSet is! Map) return null;
  final images = rawImageSet['images'];
  if (images is List && images.isNotEmpty) {
    final first = images.first;
    return first is Map ? first['url'] as String? : null;
  }
  return null;
}

class CategorySummary {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final bool featured;
  final String? imageUrl;

  const CategorySummary({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.featured,
    this.imageUrl,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    return CategorySummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      featured: json['featured'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

class ProductSummary {
  final String id;
  final String name;
  final String slug;
  final String? imageUrl;
  final double price;
  final double? compareAtPrice;
  final bool inStock;
  final double? rating;

  const ProductSummary({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    required this.price,
    this.compareAtPrice,
    this.inStock = true,
    this.rating,
  });

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    final priceObj = json['price'] as Map<String, dynamic>?;
    return ProductSummary(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      imageUrl: _firstImageUrl(json['mainImageSet']),
      price: _centsToDouble(priceObj?['regular']),
      compareAtPrice: priceObj?['compareAt'] != null
          ? _centsToDouble(priceObj!['compareAt'])
          : null,
      inStock: json['inStock'] as bool? ?? true,
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }
}

class ProductVariant {
  final String id;
  final String name;
  final double? price;
  final bool inStock;
  final Map<String, String> options;

  const ProductVariant({
    required this.id,
    required this.name,
    this.price,
    this.inStock = true,
    required this.options,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    final priceObj = json['price'] as Map<String, dynamic>?;
    final rawOptions = json['optionValues'] as Map<String, dynamic>?
        ?? json['options'] as Map<String, dynamic>?
        ?? {};
    return ProductVariant(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      price: priceObj != null ? _centsToDouble(priceObj['regular']) : null,
      inStock: json['inStock'] as bool? ?? true,
      options: rawOptions.map((k, v) => MapEntry(k, v.toString())),
    );
  }
}

class ProductDetail {
  final String id;
  final String name;
  final String slug;
  final List<String> images;
  final double price;
  final double? compareAtPrice;
  final String? description;
  final bool inStock;
  final List<ProductVariant> variants;
  final Map<String, List<String>> optionGroups;
  final double? rating;

  const ProductDetail({
    required this.id,
    required this.name,
    required this.slug,
    required this.images,
    required this.price,
    this.compareAtPrice,
    this.description,
    this.inStock = true,
    required this.variants,
    required this.optionGroups,
    this.rating,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    final priceObj = json['price'] as Map<String, dynamic>?;

    // imageSets: [{images: [{url}]}]
    final images = _extractImageUrls(json['imageSets']);

    // variants: [{id, name, optionValues: {k:v}, inStock, price, ...}]
    final rawVariants = json['variants'] as List<dynamic>? ?? [];

    // variantOptions: [{name, values: [String]}] → Map<String, List<String>>
    final rawVarOptions = json['variantOptions'] as List<dynamic>? ?? [];
    final optionGroups = <String, List<String>>{};
    for (final g in rawVarOptions) {
      if (g is Map) {
        final name = g['name'] as String? ?? '';
        final vals = (g['values'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        if (name.isNotEmpty) optionGroups[name] = vals;
      }
    }

    return ProductDetail(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      images: images,
      price: _centsToDouble(priceObj?['regular']),
      compareAtPrice: priceObj?['compareAt'] != null
          ? _centsToDouble(priceObj!['compareAt'])
          : null,
      description: json['description'] as String?,
      inStock: json['inStock'] as bool? ?? true,
      variants: rawVariants
          .map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
          .toList(),
      optionGroups: optionGroups,
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }
}

class CartLine {
  final String id;
  final String productId;
  final String productName;
  final String? imageUrl;
  final String? variantId;
  final String? variantName;
  final String? propertiesDescription;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const CartLine({
    required this.id,
    required this.productId,
    required this.productName,
    this.imageUrl,
    this.variantId,
    this.variantName,
    this.propertiesDescription,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory CartLine.fromJson(Map<String, dynamic> json) {
    return CartLine(
      id: json['entryId']?.toString() ?? json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['name'] as String? ?? json['productName'] as String? ?? '',
      imageUrl: json['thumbnailUrl'] as String? ?? json['imageUrl'] as String?,
      variantId: json['variantId']?.toString(),
      variantName: json['variantName'] as String?,
      propertiesDescription: json['propertiesDescription'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: _centsToDouble(json['unitPostTaxes'] ?? json['unitPrice']),
      totalPrice: _centsToDouble(json['totalPostTaxes'] ?? json['totalPrice']),
    );
  }

  CartLine copyWith({int? quantity}) => CartLine(
    id: id, productId: productId, productName: productName,
    imageUrl: imageUrl, variantId: variantId, variantName: variantName,
    propertiesDescription: propertiesDescription,
    quantity: quantity ?? this.quantity, unitPrice: unitPrice,
    totalPrice: unitPrice * (quantity ?? this.quantity),
  );
}

class AppliedPromotion {
  final String? displayLabel;
  final double discountAmount;
  final String? kind;

  const AppliedPromotion({this.displayLabel, required this.discountAmount, this.kind});

  factory AppliedPromotion.fromJson(Map<String, dynamic> json) {
    return AppliedPromotion(
      displayLabel: json['displayLabel'] as String?,
      discountAmount: (json['discountCents'] as num? ?? 0) / 100.0,
      kind: json['kind'] as String?,
    );
  }
}

class Cart {
  final String? id;
  final List<CartLine> lines;
  final double subtotal;
  final double? discount;
  final double? shipping;
  final double total;
  final String? discountCode;
  final String? selectedShippingId;
  final String? selectedPaymentMethod;
  final List<AppliedPromotion> appliedPromotions;

  const Cart({
    this.id,
    required this.lines,
    required this.subtotal,
    this.discount,
    this.shipping,
    required this.total,
    this.discountCode,
    this.selectedShippingId,
    this.selectedPaymentMethod,
    this.appliedPromotions = const [],
  });

  factory Cart.empty() => const Cart(lines: [], subtotal: 0, total: 0);

  factory Cart.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return Cart.empty();
    final rawLines = json['lines'] as List<dynamic>? ?? [];
    final rawPromos = json['appliedPromotions'] as List<dynamic>? ?? [];
    return Cart(
      id: json['cartId']?.toString() ?? json['id']?.toString(),
      lines: rawLines.map((l) => CartLine.fromJson(l as Map<String, dynamic>)).toList(),
      subtotal: _centsToDouble(json['productTotal'] ?? json['subtotal']),
      discount: json['totalDiscounts'] != null || json['discount'] != null
          ? _centsToDouble(json['totalDiscounts'] ?? json['discount'])
          : null,
      shipping: json['shippingTotal'] != null || json['shipping'] != null
          ? _centsToDouble(json['shippingTotal'] ?? json['shipping'])
          : null,
      total: _centsToDouble(json['totalPostTaxes'] ?? json['total']),
      discountCode: json['appliedCouponCode'] as String? ?? json['discountCode'] as String?,
      selectedShippingId: json['shippingMethodId']?.toString() ?? json['selectedShippingId'] as String?,
      selectedPaymentMethod: json['paymentMethodId']?.toString() ?? json['selectedPaymentMethod'] as String?,
      appliedPromotions: rawPromos
          .map((p) => AppliedPromotion.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

// Legacy simple ShippingOption (kept for checkout selectShippingMethod compat)
class ShippingOption {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? estimatedDelivery;
  final String? carrier;

  const ShippingOption({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.estimatedDelivery,
    this.carrier,
  });

  factory ShippingOption.fromJson(Map<String, dynamic> json) {
    return ShippingOption(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      estimatedDelivery: json['estimatedDelivery'] as String?,
      carrier: json['carrier'] as String?,
    );
  }
}

// Delivery shipping quote (one option returned by the carrier)
class DeliveryShippingItem {
  final String provider;
  final String serviceCode;
  final String name;
  final String? company;
  final int priceInCents;
  final int priceWithoutInsuranceInCents;
  final int deliveryDays;
  final String? providerData;
  final String? error;

  const DeliveryShippingItem({
    required this.provider,
    required this.serviceCode,
    required this.name,
    this.company,
    required this.priceInCents,
    this.priceWithoutInsuranceInCents = 0,
    required this.deliveryDays,
    this.providerData,
    this.error,
  });

  bool get isAvailable => error == null || error!.isEmpty;
  bool get hasInsuranceToggle =>
      priceWithoutInsuranceInCents > 0 && priceWithoutInsuranceInCents < priceInCents;

  factory DeliveryShippingItem.fromJson(Map<String, dynamic> json) {
    return DeliveryShippingItem(
      provider: json['provider'] as String? ?? '',
      serviceCode: json['serviceCode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      company: json['company'] as String?,
      priceInCents: json['priceInCents'] as int? ?? 0,
      priceWithoutInsuranceInCents: json['priceWithoutInsuranceInCents'] as int? ?? 0,
      deliveryDays: json['deliveryDays'] as int? ?? 0,
      providerData: json['providerData'] as String?,
      error: json['error'] as String?,
    );
  }
}

// One delivery split (per warehouse bucket)
class DeliveryShippingSplit {
  final String? deliveryId;
  final String? warehouseName;
  final int itemCount;
  final int preparationDays;
  final String? selectedProvider;
  final String? selectedServiceCode;
  final String shippingType; // "PHYSICAL" or "DIGITAL"
  final List<DeliveryShippingItem> options;

  const DeliveryShippingSplit({
    this.deliveryId,
    this.warehouseName,
    required this.itemCount,
    required this.preparationDays,
    this.selectedProvider,
    this.selectedServiceCode,
    required this.shippingType,
    required this.options,
  });

  bool get isDigital => shippingType == 'DIGITAL';

  factory DeliveryShippingSplit.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? [];
    return DeliveryShippingSplit(
      deliveryId: json['deliveryId']?.toString(),
      warehouseName: json['warehouseName'] as String?,
      itemCount: json['itemCount'] as int? ?? 0,
      preparationDays: json['preparationDays'] as int? ?? 0,
      selectedProvider: json['selectedProvider'] as String?,
      selectedServiceCode: json['selectedServiceCode'] as String?,
      shippingType: json['shippingType'] as String? ?? 'PHYSICAL',
      options: rawOptions
          .map((o) => DeliveryShippingItem.fromJson(o as Map<String, dynamic>))
          .where((o) => o.isAvailable)
          .toList(),
    );
  }
}

class Address {
  final String? id;
  final String street;
  final String number;
  final String? complement;
  final String neighborhood;
  final String city;
  final String state;
  final String zipCode;
  final String country;

  const Address({
    this.id,
    required this.street,
    required this.number,
    this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.zipCode,
    this.country = 'BR',
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String?,
      street: json['street'] as String? ?? '',
      number: json['number'] as String? ?? '',
      complement: json['complement'] as String?,
      neighborhood: json['neighborhood'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      zipCode: json['zipCode'] as String? ?? '',
      country: json['country'] as String? ?? 'BR',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'street': street,
        'number': number,
        'complement': complement,
        'neighborhood': neighborhood,
        'city': city,
        'state': state,
        'zipCode': zipCode,
        'country': country,
      };
}

// Place-order response from POST /api/v1/commerce/cart/checkout/place-order
class Order {
  final String id;
  final int? orderNumber;
  final String? paymentLink;
  final String? paymentAction; // NONE | REDIRECT | ON_ACCOUNT | AWAITING_APPROVAL
  final bool awaitingApproval;

  const Order({
    required this.id,
    this.orderNumber,
    this.paymentLink,
    this.paymentAction,
    this.awaitingApproval = false,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['orderId']?.toString() ?? json['id']?.toString() ?? '',
      orderNumber: json['orderNumber'] as int?,
      paymentLink: json['paymentLink'] as String?,
      paymentAction: json['paymentAction'] as String?,
      awaitingApproval: json['awaitingApproval'] as bool? ?? false,
    );
  }

  String get resolvedPaymentAction {
    if (paymentAction != null) return paymentAction!;
    if (awaitingApproval) return 'AWAITING_APPROVAL';
    if (paymentLink != null && paymentLink!.isNotEmpty) return 'REDIRECT';
    return 'NONE';
  }
}

// Customer orders list item (GET /api/v1/commerce/customer/orders).
class CustomerOrder {
  final String id;
  final int number;
  final String? statusCode;
  final String? statusLabel;
  final int totalInCents;
  final int itemsCount;
  final DateTime? createdAt;

  const CustomerOrder({
    required this.id,
    required this.number,
    this.statusCode,
    this.statusLabel,
    required this.totalInCents,
    required this.itemsCount,
    this.createdAt,
  });

  double get total => totalInCents / 100.0;

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    return CustomerOrder(
      id: json['id']?.toString() ?? '',
      number: json['number'] as int? ?? 0,
      statusCode: json['statusCode'] as String?,
      statusLabel: json['statusLabel'] as String?,
      totalInCents: json['totalInCents'] as int? ?? 0,
      itemsCount: json['itemsCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}

class OrderItem {
  final String entryId;
  final String? productId;
  final String? variantId;
  final String? name;
  final String? variantName;
  final int quantity;
  final double unitPrice;

  const OrderItem({
    required this.entryId,
    this.productId,
    this.variantId,
    this.name,
    this.variantName,
    required this.quantity,
    required this.unitPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      entryId: json['entryId']?.toString() ?? '',
      productId: json['productId']?.toString(),
      variantId: json['variantId']?.toString(),
      name: json['name'] as String?,
      variantName: json['variantName'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: _centsToDouble(json['unitPricePostTaxes']),
    );
  }
}

class CustomerProfile {
  final String id;
  final String email;
  final String firstname;
  final String lastname;
  final String? phone;
  final bool guest;
  final bool active;

  const CustomerProfile({
    required this.id,
    required this.email,
    required this.firstname,
    required this.lastname,
    this.phone,
    this.guest = false,
    this.active = true,
  });

  String get fullName => '$firstname $lastname'.trim();

  String get initials {
    final f = firstname.isNotEmpty ? firstname[0].toUpperCase() : '';
    final l = lastname.isNotEmpty ? lastname[0].toUpperCase() : '';
    final combined = '$f$l';
    return combined.isNotEmpty ? combined : (email.isNotEmpty ? email[0].toUpperCase() : '?');
  }

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      id: json['id']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      firstname: json['firstname'] as String? ?? '',
      lastname: json['lastname'] as String? ?? '',
      phone: json['phone'] as String?,
      guest: json['guest'] as bool? ?? false,
      active: json['active'] as bool? ?? true,
    );
  }
}

class CustomerAddress {
  final String id;
  final String name;
  final String street;
  final String number;
  final String? details;
  final String district;
  final String city;
  final String zip;
  final String? stateCode;
  final String? stateName;
  final String? stateId;
  final String? countryId;

  const CustomerAddress({
    required this.id,
    required this.name,
    required this.street,
    required this.number,
    this.details,
    required this.district,
    required this.city,
    required this.zip,
    this.stateCode,
    this.stateName,
    this.stateId,
    this.countryId,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id:        json['id']?.toString() ?? '',
      name:      json['name'] as String? ?? '',
      street:    json['street'] as String? ?? '',
      number:    json['number'] as String? ?? '',
      details:   json['details'] as String?,
      district:  json['district'] as String? ?? '',
      city:      json['city'] as String? ?? '',
      zip:       json['zip'] as String? ?? '',
      stateCode: json['stateCode'] as String?,
      stateName: json['stateName'] as String?,
      stateId:   json['stateId']?.toString(),
      countryId: json['countryId']?.toString(),
    );
  }
}
