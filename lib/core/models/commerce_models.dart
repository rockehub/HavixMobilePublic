class ProductSummary {
  final String id;
  final String name;
  final String slug;
  final String? imageUrl;
  final double price;
  final double? compareAtPrice;
  final String? currency;
  final bool inStock;
  final double? rating;
  final int? reviewCount;

  const ProductSummary({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    required this.price,
    this.compareAtPrice,
    this.currency,
    this.inStock = true,
    this.rating,
    this.reviewCount,
  });

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    return ProductSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      compareAtPrice: (json['compareAtPrice'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      inStock: json['inStock'] as bool? ?? true,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'] as int?,
    );
  }
}

class ProductVariant {
  final String id;
  final String name;
  final String? sku;
  final double? price;
  final bool inStock;
  final Map<String, String> options;

  const ProductVariant({
    required this.id,
    required this.name,
    this.sku,
    this.price,
    this.inStock = true,
    required this.options,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as Map<String, dynamic>? ?? {};
    return ProductVariant(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String?,
      price: (json['price'] as num?)?.toDouble(),
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
  final String? currency;
  final String? description;
  final bool inStock;
  final List<ProductVariant> variants;
  final Map<String, List<String>> optionGroups;
  final double? rating;
  final int? reviewCount;
  final Map<String, dynamic>? meta;

  const ProductDetail({
    required this.id,
    required this.name,
    required this.slug,
    required this.images,
    required this.price,
    this.compareAtPrice,
    this.currency,
    this.description,
    this.inStock = true,
    required this.variants,
    required this.optionGroups,
    this.rating,
    this.reviewCount,
    this.meta,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'] as List<dynamic>? ?? [];
    final rawVariants = json['variants'] as List<dynamic>? ?? [];
    final rawOptionGroups = json['optionGroups'] as Map<String, dynamic>? ?? {};
    return ProductDetail(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      images: rawImages.map((e) => e.toString()).toList(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      compareAtPrice: (json['compareAtPrice'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      description: json['description'] as String?,
      inStock: json['inStock'] as bool? ?? true,
      variants: rawVariants
          .map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
          .toList(),
      optionGroups: rawOptionGroups.map(
        (k, v) => MapEntry(
          k,
          (v as List<dynamic>).map((e) => e.toString()).toList(),
        ),
      ),
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'] as int?,
      meta: json['meta'] as Map<String, dynamic>?,
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
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory CartLine.fromJson(Map<String, dynamic> json) {
    return CartLine(
      id: json['id'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      variantId: json['variantId'] as String?,
      variantName: json['variantName'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  CartLine copyWith({int? quantity}) {
    return CartLine(
      id: id,
      productId: productId,
      productName: productName,
      imageUrl: imageUrl,
      variantId: variantId,
      variantName: variantName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice,
      totalPrice: unitPrice * (quantity ?? this.quantity),
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
  });

  factory Cart.empty() => const Cart(lines: [], subtotal: 0, total: 0);

  factory Cart.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List<dynamic>? ?? [];
    return Cart(
      id: json['id'] as String?,
      lines: rawLines
          .map((l) => CartLine.fromJson(l as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble(),
      shipping: (json['shipping'] as num?)?.toDouble(),
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      discountCode: json['discountCode'] as String?,
      selectedShippingId: json['selectedShippingId'] as String?,
      selectedPaymentMethod: json['selectedPaymentMethod'] as String?,
    );
  }
}

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

class Order {
  final String id;
  final String status;
  final List<CartLine> lines;
  final double total;
  final Address? shippingAddress;
  final String? paymentMethod;
  final DateTime? createdAt;
  final String? trackingCode;

  const Order({
    required this.id,
    required this.status,
    required this.lines,
    required this.total,
    this.shippingAddress,
    this.paymentMethod,
    this.createdAt,
    this.trackingCode,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List<dynamic>? ?? [];
    return Order(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      lines: rawLines
          .map((l) => CartLine.fromJson(l as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      shippingAddress: json['shippingAddress'] != null
          ? Address.fromJson(json['shippingAddress'] as Map<String, dynamic>)
          : null,
      paymentMethod: json['paymentMethod'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      trackingCode: json['trackingCode'] as String?,
    );
  }
}

class CustomerProfile {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final List<Address> addresses;

  const CustomerProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.addresses,
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    final rawAddresses = json['addresses'] as List<dynamic>? ?? [];
    return CustomerProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      addresses: rawAddresses
          .map((a) => Address.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}
