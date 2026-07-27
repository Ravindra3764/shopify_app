import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/routing/app_routes.dart';
import 'package:shopify_app/features/cart/presentation/providers/cart_providers.dart';
import 'package:shopify_app/shared/widgets/app_snack_bar.dart';
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

/// Wraps a branch tab's root screen to give the Android system back button
/// e-commerce behavior.
///
/// Must sit *inside* each [StatefulShellBranch]'s navigator — a [PopScope] on
/// the shell itself never fires for indexed-stack root pages (go_router only
/// consults the active branch's navigator), so it is applied per branch here.
///
/// From any non-Home tab ([isHome] false), back returns to the Home tab. On
/// Home, the first back shows a "press again to exit" toast and only a second
/// back within a short window leaves the app.
class ShellBackHandler extends StatefulWidget {
  const ShellBackHandler({
    required this.child,
    this.isHome = false,
    super.key,
  });

  final Widget child;

  /// Whether this wraps the Home tab, which owns the exit prompt.
  final bool isHome;

  @override
  State<ShellBackHandler> createState() => _ShellBackHandlerState();
}

class _ShellBackHandlerState extends State<ShellBackHandler> {
  /// Window in which a second back press on Home exits the app. Matches the
  /// exit-toast duration so the prompt and the window disappear together.
  static const _exitWindow = Duration(seconds: 2);

  /// When the last back was pressed on Home; a second within [_exitWindow]
  /// exits. Null until the first back on Home.
  DateTime? _lastHomeBack;

  void _handleBack() {
    // Off Home: switch the shell back to the Home tab rather than exit.
    if (!widget.isHome) {
      context.go(AppRoutes.home);
      return;
    }

    // On Home: first back prompts, a second back within the window exits.
    final now = DateTime.now();
    final last = _lastHomeBack;
    if (last == null || now.difference(last) > _exitWindow) {
      _lastHomeBack = now;
      showAppSnackBar(context, 'Press back again to exit');
      return;
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // We resolve every back gesture ourselves (home-jump or exit-prompt).
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: widget.child,
    );
  }
}
