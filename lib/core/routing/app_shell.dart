import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/features/cart/presentation/providers/cart_providers.dart';
import 'package:shopify_app/shared/widgets/app_snack_bar.dart';
import 'package:shopify_app/shared/widgets/floating_bottom_nav_bar.dart';

/// Hosts the four persistent tabs (Home, Shop, Cart, Profile) and their
/// floating bottom nav.
///
/// Intercepts the Android system back button ([PopScope]): from any non-Home
/// tab, back returns to Home first; on Home, a single back shows a
/// "press again to exit" toast and only a second back within a short window
/// leaves the app. Pushed full-screen routes sit above this shell, so their
/// back still pops normally.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// Index of the Home branch in the shell.
  static const _homeIndex = 0;

  /// Window in which a second back press on Home exits the app. Matches the
  /// exit-toast duration so the prompt and the window disappear together.
  static const _exitWindow = Duration(seconds: 2);

  /// When the last back was pressed on Home; a second within [_exitWindow]
  /// exits. Null until the first back on Home.
  DateTime? _lastHomeBack;

  void _handleBack() {
    final shell = widget.navigationShell;

    // Off Home: send them to Home rather than out of the app.
    if (shell.currentIndex != _homeIndex) {
      shell.goBranch(_homeIndex);
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
    return PopScope(
      // We resolve every back gesture ourselves (home-jump or exit-prompt).
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: widget.navigationShell),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingBottomNavBar(
                items: items,
                currentIndex: widget.navigationShell.currentIndex,
                onTap: (index) => widget.navigationShell.goBranch(
                  index,
                  initialLocation: index == widget.navigationShell.currentIndex,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
