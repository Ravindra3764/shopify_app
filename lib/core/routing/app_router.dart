import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/routing/app_routes.dart';
import 'package:shopify_app/core/routing/app_shell.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:shopify_app/features/auth/presentation/screens/login_screen.dart';
import 'package:shopify_app/features/auth/presentation/screens/register_screen.dart';
import 'package:shopify_app/features/cart/presentation/screens/cart_screen.dart';
import 'package:shopify_app/features/checkout/domain/order_confirmation.dart';
import 'package:shopify_app/features/checkout/presentation/screens/checkout_payment_screen.dart';
import 'package:shopify_app/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:shopify_app/features/checkout/presentation/screens/order_confirmed_screen.dart';
import 'package:shopify_app/features/home/presentation/screens/home_screen.dart';
import 'package:shopify_app/features/product_detail/domain/product_peek_args.dart';
import 'package:shopify_app/features/product_detail/presentation/screens/product_detail_screen.dart';
import 'package:shopify_app/features/product_detail/presentation/screens/product_sheet_screen.dart';
import 'package:shopify_app/features/product_listing/presentation/screens/collection_screen.dart';
import 'package:shopify_app/features/profile/domain/profile_content.dart';
import 'package:shopify_app/features/profile/presentation/screens/addresses_screen.dart';
import 'package:shopify_app/features/profile/presentation/screens/content_page_screen.dart';
import 'package:shopify_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:shopify_app/features/search/presentation/screens/search_screen.dart';
import 'package:shopify_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:shopify_app/features/wishlist/presentation/screens/wishlist_screen.dart';

/// Builds the app's [GoRouter].
///
/// Routes are declared with paths from [AppRoutes] so deep links
/// (`/collection/men`) resolve to the right screen without extra wiring.
/// Home/Cart/Profile live under a [StatefulShellRoute] so [AppShell]'s
/// floating bottom nav persists across them, each keeping its own stack;
/// collection/product-detail push full-screen on top, hiding the nav.
GoRouter createRouter({bool sheetProductDetail = false}) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.cart,
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.collection,
        name: AppRoutes.collectionName,
        builder: (context, state) {
          final handle = state.pathParameters['handle'] ?? '';
          // Title is passed as typed `extra` from in-app links; deep links omit
          // it, so the screen falls back to the fetched collection name.
          final title = state.extra is String ? state.extra! as String : null;
          return CollectionScreen(handle: handle, title: title);
        },
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        name: AppRoutes.productDetailName,
        pageBuilder: (context, state) {
          final handle = state.pathParameters['handle'] ?? '';
          final peek = state.extra is ProductPeekArgs
              ? state.extra! as ProductPeekArgs
              : null;
          // Blinkit-style sheet only when enabled AND opened from a list
          // (siblings to swipe through); deep links fall back to classic.
          if (sheetProductDetail && peek != null && peek.handles.isNotEmpty) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              opaque: false,
              barrierDismissible: true,
              barrierColor: AppColors.scrim,
              transitionsBuilder: (context, animation, _, child) =>
                  SlideTransition(
                    position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                        .animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: child,
                  ),
              child: ProductSheetScreen(peek: peek),
            );
          }
          return MaterialPage<void>(
            key: state.pageKey,
            child: ProductDetailScreen(handle: handle),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.addresses,
        builder: (context, state) => const AddressesScreen(),
      ),
      GoRoute(
        path: AppRoutes.content,
        builder: (context, state) => ContentPageScreen(
          // The entry to display is passed as typed `extra`; default to the
          // privacy policy for an unexpected/deep-link hit.
          content: state.extra is ProfileContent
              ? state.extra! as ProfileContent
              : ProfileContent.privacyPolicy,
        ),
      ),
      GoRoute(
        path: AppRoutes.wishlist,
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkoutPay,
        builder: (context, state) {
          // Hosted checkout URL passed as typed `extra` from the review step.
          final url = state.extra is String ? state.extra! as String : '';
          return CheckoutPaymentScreen(checkoutUrl: url);
        },
      ),
      GoRoute(
        path: AppRoutes.orderConfirmed,
        builder: (context, state) => OrderConfirmedScreen(
          confirmation: state.extra is OrderConfirmation
              ? state.extra! as OrderConfirmation
              : null,
        ),
      ),
    ],
  );
}
