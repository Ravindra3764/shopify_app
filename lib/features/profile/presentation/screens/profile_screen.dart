import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/routing/app_routes.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:shopify_app/features/auth/presentation/providers/auth_state.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/shared/widgets/app_snack_bar.dart';
import 'package:shopify_app/shared/widgets/custom_background.dart';
import 'package:shopify_app/shared/widgets/custom_button.dart';
import 'package:shopify_app/shared/widgets/empty_state_view.dart';
import 'package:shopify_app/shared/widgets/error_view.dart';
import 'package:shopify_app/shopify/models/customer.dart';

/// Profile tab. Shows a sign-in prompt while signed out and the customer's
/// account (details, quick links, sign-out) once authenticated. Auth state
/// comes from [authProvider], so it flips automatically on login/logout.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);
    return CustomBackground(
      showBackButton: false,
      title: 'Profile',
      child: authAsync.when(
        // Session restore is resolved app-wide at launch, so this is a brief
        // gate rather than content loading.
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorView(
          message: 'Could not load your profile.',
          onRetry: () => ref.invalidate(authProvider),
        ),
        data: (state) => switch (state) {
          Authenticated(:final customer) => _ProfileAccount(customer: customer),
          Unauthenticated() => const _ProfileGuest(),
        },
      ),
    );
  }
}

/// Signed-out view: prompt to sign in.
class _ProfileGuest extends StatelessWidget {
  const _ProfileGuest();

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      icon: Icons.person_outline,
      message: 'Sign in to view your profile and orders.',
      actionLabel: 'Sign in',
      onAction: () => context.push(AppRoutes.login),
    );
  }
}

/// Signed-in view: identity header, quick links, and sign-out.
class _ProfileAccount extends ConsumerWidget {
  const _ProfileAccount({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final wishlistEnabled = ref.watch(featureFlagsProvider).wishlistEnabled;

    return ListView(
      children: [
        const SizedBox(height: AppSpacing.md),
        _Identity(customer: customer),
        const SizedBox(height: AppSpacing.xl),
        _ProfileTile(
          icon: Icons.receipt_long_outlined,
          label: 'My orders',
          onTap: () => showAppSnackBar(context, 'Orders are coming soon.'),
        ),
        if (wishlistEnabled)
          _ProfileTile(
            icon: Icons.favorite_border,
            label: 'Wishlist',
            onTap: () => context.push(AppRoutes.wishlist),
          ),
        _ProfileTile(
          icon: Icons.location_on_outlined,
          label: 'Addresses',
          onTap: () => showAppSnackBar(context, 'Addresses are coming soon.'),
        ),
        const SizedBox(height: AppSpacing.xl),
        CustomButton.outline(
          label: 'Sign out',
          onPressed: () => ref.read(authProvider.notifier).logout(),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text(
            customer.email,
            style: textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
          ),
        ),
      ],
    );
  }
}

/// Avatar + name + email header.
class _Identity extends StatelessWidget {
  const _Identity({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        CircleAvatar(
          radius: AppDimensions.avatarRadius,
          backgroundColor: AppColors.primary,
          child: Text(
            _initials(customer),
            style: textTheme.titleMedium?.copyWith(color: AppColors.white),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer.displayName,
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                customer.email,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// One or two uppercase initials from the customer's name, else '?'.
  String _initials(Customer customer) {
    final parts = [
      ?customer.firstName,
      ?customer.lastName,
    ].where((p) => p.trim().isNotEmpty).toList();
    if (parts.isEmpty) {
      final email = customer.email.trim();
      return email.isEmpty ? '?' : email[0].toUpperCase();
    }
    return parts.map((p) => p.trim()[0].toUpperCase()).take(2).join();
  }
}

/// A tappable account row: leading [icon], [label], trailing chevron.
class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.textSecondary,
              size: AppDimensions.iconMd,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
              size: AppDimensions.iconMd,
            ),
          ],
        ),
      ),
    );
  }
}
