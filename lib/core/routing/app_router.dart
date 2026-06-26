import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/routing/app_routes.dart';
import 'package:shopify_app/features/home/presentation/screens/home_screen.dart';
import 'package:shopify_app/features/product_listing/presentation/screens/collection_screen.dart';
import 'package:shopify_app/features/splash/presentation/screens/splash_screen.dart';

/// Builds the app's [GoRouter].
///
/// Routes are declared with paths from [AppRoutes] so deep links
/// (`/collection/men`) resolve to the right screen without extra wiring.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
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
    ],
  );
}
