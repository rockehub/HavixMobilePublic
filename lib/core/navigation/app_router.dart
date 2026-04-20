import 'package:go_router/go_router.dart';
import '../../pages/home_screen.dart';
import '../../pages/product_screen.dart';
import '../../pages/category_screen.dart';
import '../../pages/search_screen.dart';
import '../../pages/cart_screen.dart';
import '../../pages/checkout_screen.dart';
import '../../pages/auth_screen.dart';
import '../../pages/account_screen.dart';
import '../../pages/orders_screen.dart';
import '../../pages/order_detail_screen.dart';
import '../../pages/content_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (ctx, state) => const HomeScreen()),
    GoRoute(
      path: '/product/:slug',
      builder: (ctx, state) => ProductScreen(slug: state.pathParameters['slug']!),
    ),
    GoRoute(
      path: '/category/:slug',
      builder: (ctx, state) => CategoryScreen(slug: state.pathParameters['slug']!),
    ),
    GoRoute(
      path: '/search',
      builder: (ctx, state) => SearchScreen(query: state.uri.queryParameters['q'] ?? ''),
    ),
    GoRoute(path: '/cart', builder: (ctx, state) => const CartScreen()),
    GoRoute(path: '/checkout', builder: (ctx, state) => const CheckoutScreen()),
    GoRoute(path: '/login', builder: (ctx, state) => const AuthScreen()),
    GoRoute(path: '/account', builder: (ctx, state) => const AccountScreen()),
    GoRoute(path: '/orders', builder: (ctx, state) => const OrdersScreen()),
    GoRoute(
      path: '/orders/:id',
      builder: (ctx, state) => OrderDetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/p/:path',
      builder: (ctx, state) => ContentScreen(path: state.pathParameters['path']!),
    ),
  ],
);
