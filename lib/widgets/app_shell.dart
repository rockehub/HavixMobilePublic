import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/store/cart_store.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static const _tabs = [
    _Tab('/', Icons.home_outlined, Icons.home_rounded, 'Início'),
    _Tab('/search', Icons.search_outlined, Icons.search_rounded, 'Buscar'),
    _Tab('/cart', Icons.shopping_bag_outlined, Icons.shopping_bag_rounded, 'Carrinho'),
    _Tab('/account', Icons.person_outline_rounded, Icons.person_rounded, 'Conta'),
  ];

  int _activeIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (var i = _tabs.length - 1; i >= 0; i--) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _activeIndex(context);
    final cartLines = context.watch<CartStore>().cart.lines.length;

    return Scaffold(
      // MediaQuery removes bottom padding so existing SafeAreas inside
      // each screen don't double-pad below the NavigationBar.
      body: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: child,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeIndex,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: _tabs.map((tab) {
          final isCart = tab.path == '/cart';
          final icon = Icon(tab.icon);
          final selectedIcon = Icon(tab.selectedIcon);

          return NavigationDestination(
            icon: isCart && cartLines > 0
                ? Badge(label: Text('$cartLines'), child: icon)
                : icon,
            selectedIcon: isCart && cartLines > 0
                ? Badge(label: Text('$cartLines'), child: selectedIcon)
                : selectedIcon,
            label: tab.label,
          );
        }).toList(),
      ),
    );
  }
}

class _Tab {
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _Tab(this.path, this.icon, this.selectedIcon, this.label);
}
