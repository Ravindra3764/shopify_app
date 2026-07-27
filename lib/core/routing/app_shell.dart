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
/// Gives the Android system back button e-commerce behavior via
/// [BackButtonListener] — which hooks go_router's root back dispatcher, unlike
/// a [PopScope] on the shell, which never fires for indexed-stack branch roots.
/// When a full-screen route is pushed on top (product detail, login…) the root
/// navigator can pop, so back is left to it. On a bare tab, back off Home
/// returns to Home; on Home a first back prompts and a second within a short
/// window exits.
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

  /// Handles the system back button. Returns `true` when consumed, `false` to
  /// let go_router pop as usual (a pushed full-screen route).
  Future<bool> _onBack() async {
    // A full-screen route is stacked above the shell — let it pop normally.
    if (Navigator.of(context, rootNavigator: true).canPop()) return false;

    final shell = widget.navigationShell;

    // Off Home: send them to Home rather than out of the app.
    if (shell.currentIndex != _homeIndex) {
      shell.goBranch(_homeIndex);
      return true;
    }

    // On Home: first back prompts, a second back within the window exits.
    final now = DateTime.now();
    final last = _lastHomeBack;
    if (last == null || now.difference(last) > _exitWindow) {
      _lastHomeBack = now;
      showAppSnackBar(context, 'Press back again to exit');
      return true;
    }
    await SystemNavigator.pop();
    return true;
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
    return BackButtonListener(
      onBackButtonPressed: _onBack,
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
