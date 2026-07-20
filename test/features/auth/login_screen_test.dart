import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopify_app/core/storage/auth_storage.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/features/auth/presentation/screens/login_screen.dart';
import 'package:shopify_app/providers/storage_providers.dart';

/// No stored session → the notifier resolves to Unauthenticated.
class _EmptyAuthStorage implements AuthStorage {
  @override
  Future<String?> readToken() async => null;
  @override
  Future<DateTime?> readExpiry() async => null;
  @override
  Future<void> write(String token, DateTime expiresAt) async {}
  @override
  Future<void> clear() async {}
}

void main() {
  setUpAll(() {
    AppColors.primary = const Color(0xFF086C4C);
    AppColors.secondary = const Color(0xFF625B71);
    AppColors.accent = const Color(0xFF7D5260);
  });

  testWidgets('LoginScreen renders its form and links', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authStorageProvider.overrideWithValue(_EmptyAuthStorage())],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });

  testWidgets('empty submit shows validation errors', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authStorageProvider.overrideWithValue(_EmptyAuthStorage())],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the "Sign in" button (last matching widget is the CTA).
    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle();

    expect(find.text('Enter your email.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
  });
}
