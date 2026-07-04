import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/routing/app_router.dart';

/// App-wide [GoRouter]. Built once and reused for the app's lifetime.
final routerProvider = Provider<GoRouter>((ref) => createRouter());
