import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/cart/presentation/providers/cart_providers.dart';
import 'package:shopify_app/features/wishlist/presentation/providers/wishlist_providers.dart';
import 'package:shopify_app/providers/config_providers.dart';

/// Home top bar: menu, centered store name, wishlist, cart.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key, this.onMenu, this.onCart, this.onWishlist});

  final VoidCallback? onMenu;
  final VoidCallback? onCart;

  /// Opens the wishlist. `null` hides the heart — e.g. tenants with the
  /// wishlist feature disabled.
  final VoidCallback? onWishlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appName = ref.watch(appConfigProvider).appName;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _IconButton(icon: Icons.menu, onTap: onMenu),
          Expanded(
            child: Text(
              appName.toUpperCase(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: AppSpacing.xs / 2,
              ),
            ),
          ),
          if (onWishlist != null) ...[
            _BadgedIcon(
              icon: Icons.favorite_border,
              count: ref.watch(wishlistCountProvider),
              onTap: onWishlist,
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          _BadgedIcon(
            icon: Icons.shopping_bag_outlined,
            count: ref.watch(cartCountProvider),
            onTap: onCart,
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      child: Icon(
        icon,
        size: AppDimensions.iconMd,
        color: AppColors.textPrimary,
      ),
    );
  }
}

/// An icon with a count badge that appears once [count] is positive.
class _BadgedIcon extends StatelessWidget {
  const _BadgedIcon({required this.icon, required this.count, this.onTap});

  final IconData icon;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, size: AppDimensions.iconMd, color: AppColors.textPrimary),
          if (count > 0)
            Positioned(
              top: -AppSpacing.sm,
              right: -AppSpacing.sm,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: AppDimensions.cartBadgeSize,
                ),
                height: AppDimensions.cartBadgeSize,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.cartBadgeSize,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 99 ? '99+' : '$count',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
