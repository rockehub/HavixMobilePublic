import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../api/commerce_api.dart';
import '../models/commerce_models.dart';

class CartStore extends ChangeNotifier {
  final _api = CommerceApi();

  Cart cart = Cart.empty();
  bool isLoading = false;

  int get itemCount => cart.lines.fold(0, (s, l) => s + l.quantity);

  void clear() {
    cart = Cart.empty();
    notifyListeners();
  }

  Future<void> fetchCart() async {
    isLoading = true;
    notifyListeners();
    try {
      cart = await _api.getCart();
    } catch (_) {}
    isLoading = false;
    notifyListeners();
  }

  String? _lastError;
  String? get lastError => _lastError;

  Future<bool> addToCart(String? variantId, int qty, {String? productId}) async {
    isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      cart = await _api.addToCart(variantId, qty, productId: productId);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateItem(String lineId, int qty) async {
    try {
      cart = await _api.updateCartItem(lineId, qty);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> removeItem(String lineId) async {
    try {
      cart = await _api.removeCartItem(lineId);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> applyDiscount(String code) async {
    try {
      cart = await _api.applyDiscount(code);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> removeDiscount() async {
    final code = cart.discountCode;
    if (code == null || code.isEmpty) return;
    try {
      cart = await _api.removeDiscount(code);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> selectShipping(String methodId) async {
    try {
      cart = await _api.selectShippingMethod(methodId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> selectPayment(String methodId, [Map<String, dynamic>? data]) async {
    try {
      cart = await _api.selectPaymentMethod(methodId);
      notifyListeners();
    } catch (_) {}
  }

  Future<Order?> placeOrder() async {
    isLoading = true;
    notifyListeners();
    try {
      final order = await _api.placeOrder();
      if (kDebugMode) {
        debugPrint('[CartStore] placeOrder ok id=${order.id} action=${order.resolvedPaymentAction} link=${order.paymentLink}');
      }
      cart = Cart.empty();
      isLoading = false;
      notifyListeners();
      return order;
    } catch (e) {
      if (kDebugMode) debugPrint('[CartStore] placeOrder error: $e');
      isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
