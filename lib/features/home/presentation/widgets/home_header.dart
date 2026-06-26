import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/providers/config_providers.dart';

/// Home top bar: menu, centered store name, cart.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key, this.onMenu, this.onCart});

  final VoidCallback? onMenu;
  final VoidCallback? onCart;

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
          _IconButton(icon: Icons.shopping_bag_outlined, onTap: onCart),
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
