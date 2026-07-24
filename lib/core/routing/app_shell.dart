import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/features/cart/presentation/providers/cart_providers.dart';
import 'package:shopify_app/shared/widgets/floating_bottom_nav_bar.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);
    final items = [
      const FloatingNavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
      ),
      const FloatingNavItem(
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view,
        label: 'Shop',
      ),
      FloatingNavItem(
        icon: Icons.shopping_bag_outlined,
        activeIcon: Icons.shopping_bag,
        label: 'Cart',
        badgeCount: cartCount,
      ),
      const FloatingNavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
      ),
    ];
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: navigationShell),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingBottomNavBar(
              items: items,
              currentIndex: navigationShell.currentIndex,
              onTap: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
