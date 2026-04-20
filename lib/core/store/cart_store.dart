import 'package:flutter/material.dart';
import '../api/commerce_api.dart';
import '../models/commerce_models.dart';

class CartStore extends ChangeNotifier {
  final _api = CommerceApi();

  Cart cart = Cart.empty();
  bool isLoading = false;
  List<ShippingOption> shippingOptions = [];

  int get itemCount => cart.lines.fold(0, (s, l) => s + l.quantity);

  Future<void> fetchCart() async {
    isLoading = true;
    notifyListeners();
    try {
      cart = await _api.getCart();
    } catch (_) {}
    isLoading = false;
    notifyListeners();
  }

  Future<void> addToCart(String variantId, int qty) async {
    isLoading = true;
    notifyListeners();
    try {
      cart = await _api.addToCart(variantId, qty);
    } catch (_) {}
    isLoading = false;
    notifyListeners();
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
    try {
      cart = await _api.removeDiscount();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchShippingOptions(String zipCode) async {
    try {
      shippingOptions = await _api.getShippingOptions(zipCode);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> selectShipping(String optionId) async {
    try {
      cart = await _api.selectShipping(optionId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> selectPayment(String method, Map<String, dynamic> data) async {
    try {
      cart = await _api.selectPayment(method, data);
      notifyListeners();
    } catch (_) {}
  }

  Future<Order?> placeOrder() async {
    isLoading = true;
    notifyListeners();
    try {
      final order = await _api.placeOrder();
      cart = Cart.empty();
      isLoading = false;
      notifyListeners();
      return order;
    } catch (_) {
      isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
