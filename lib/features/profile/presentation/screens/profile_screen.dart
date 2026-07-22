import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/routing/app_routes.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:shopify_app/features/profile/domain/profile_content.dart';
import 'package:shopify_app/features/profile/presentation/providers/content_providers.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/shared/widgets/confirm_dialog.dart';
import 'package:shopify_app/shared/widgets/custom_background.dart';
import 'package:shopify_app/shared/widgets/custom_button.dart';
import 'package:shopify_app/shopify/models/customer.dart';

/// Profile tab. The account menu (orders, addresses, policies…) is always
/// visible; only the top card swaps — a sign-in/sign-up prompt while signed
/// out, the customer's identity + sign-out once authenticated. Account-only
/// actions route to sign-in when tapped by a guest.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  /// Confirms before signing out, so an accidental tap doesn't end the session.
  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Sign out',
      message: 'Are you sure you want to sign out?',
      confirmLabel: 'Sign out',
      isDestructive: true,
    );
    if (confirmed) await ref.read(authProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = ref.watch(currentCustomerProvider);
    final isAuthed = customer != null;
    final config = ref.watch(appConfigProvider);
    final wishlistEnabled = config.features.wishlistEnabled;
    // Empty until the policy links load; tiles pop in once available.
    final availablePolicies =
        ref.watch(availablePoliciesProvider).valueOrNull ??
        const <ProfileContent>{};

    /// Runs [action] when signed in, otherwise routes the guest to sign-in.
    void gated(VoidCallback action) {
      if (isAuthed) {
        action();
      } else {
        context.push(AppRoutes.login);
      }
    }

    /// Opens a static store-content page (privacy, terms, about, help).
    void openContent(ProfileContent content) =>
        context.push(AppRoutes.content, extra: content);

    return CustomBackground(
      showBackButton: false,
      title: 'Profile',
      child: ListView(
        // Clear the floating bottom nav so the sign-out button isn't hidden.
        padding: const EdgeInsets.only(
          bottom: AppDimensions.floatingNavClearance,
        ),
        children: [
          const SizedBox(height: AppSpacing.sm),
          if (isAuthed)
            _IdentityCard(customer: customer)
          else
            const _SignInCard(),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Account'),
          _ProfileTile(
            icon: Icons.receipt_long_outlined,
            label: 'My orders',
            onTap: () => gated(() => context.push(AppRoutes.orders)),
          ),
          _ProfileTile(
            icon: Icons.location_on_outlined,
            label: 'Addresses',
            onTap: () => context.push(AppRoutes.addresses),
          ),
          if (wishlistEnabled)
            _ProfileTile(
              icon: Icons.favorite_border,
              label: 'Wishlist',
              onTap: () => context.push(AppRoutes.wishlist),
            ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('More'),
          // Only the store policies the merchant has actually configured
          // (Settings → Policies) are shown, in a stable order.
          for (final policy in ProfileContent.policies)
            if (availablePolicies.contains(policy))
              _ProfileTile(
                icon: _contentIcon(policy),
                label: policy.title,
                onTap: () => openContent(policy),
              ),
          // About / Help pages are optional per tenant — shown only when a
          // page handle is configured.
          if (config.aboutPageHandle != null)
            _ProfileTile(
              icon: _contentIcon(ProfileContent.about),
              label: ProfileContent.about.title,
              onTap: () => openContent(ProfileContent.about),
            ),
          if (config.helpPageHandle != null)
            _ProfileTile(
              icon: _contentIcon(ProfileContent.help),
              label: ProfileContent.help.title,
              onTap: () => openContent(ProfileContent.help),
            ),
          if (isAuthed) ...[
            const SizedBox(height: AppSpacing.xl),
            CustomButton.outline(
              label: 'Sign out',
              onPressed: () => _confirmSignOut(context, ref),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// Menu icon for a static-content entry.
IconData _contentIcon(ProfileContent content) => switch (content) {
  ProfileContent.privacyPolicy => Icons.privacy_tip_outlined,
  ProfileContent.terms => Icons.description_outlined,
  ProfileContent.refund => Icons.assignment_return_outlined,
  ProfileContent.shipping => Icons.local_shipping_outlined,
  ProfileContent.subscription => Icons.event_repeat_outlined,
  ProfileContent.about => Icons.info_outline,
  ProfileContent.help => Icons.help_outline,
};

/// Signed-out header: prompt to sign in or create an account.
class _SignInCard extends StatelessWidget {
  const _SignInCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome',
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Sign in or create an account to track orders and save addresses.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: CustomButton.primary(
                  label: 'Log in',
                  onPressed: () => context.push(AppRoutes.login),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: CustomButton.outline(
                  label: 'Sign up',
                  onPressed: () => context.push(AppRoutes.register),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Signed-in header: avatar + name + email.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
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
      ),
    );
  }

  /// One or two uppercase initials from the customer's name, else the email.
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

/// Small uppercase group label above a menu section.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.textTertiary,
          letterSpacing: 0.5,
        ),
      ),
    );
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
