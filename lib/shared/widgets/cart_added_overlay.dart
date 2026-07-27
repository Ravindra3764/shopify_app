import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/config/cart_added_style.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/shared/widgets/app_snack_bar.dart';

/// Confirms a successful add-to-cart in the tenant's configured style
/// ([CartAddedStyle]): a bottom toast, or a centered check-mark overlay.
///
/// ```dart
/// showCartAddedFeedback(context, ref);
/// ```
void showCartAddedFeedback(BuildContext context, WidgetRef ref) {
  showAddedFeedback(
    context,
    ref,
    icon: Icons.check,
    toastIcon: Icons.shopping_bag,
    toastMessage: 'Added to cart',
    overlayMessage: 'Product added\nto the cart',
  );
}

/// Confirms a successful add (cart, wishlist, …) in the tenant's configured
/// [CartAddedStyle]: a bottom toast, or a centered overlay showing [icon] over
/// [overlayMessage]. The toast variant uses [toastIcon] and [toastMessage].
///
/// ```dart
/// showAddedFeedback(context, ref,
///   icon: Icons.favorite, toastIcon: Icons.favorite,
///   toastMessage: 'Added to wishlist', overlayMessage: 'Added to\nwishlist');
/// ```
void showAddedFeedback(
  BuildContext context,
  WidgetRef ref, {
  required IconData icon,
  required IconData toastIcon,
  required String toastMessage,
  required String overlayMessage,
}) {
  final style = ref.read(appConfigProvider).cartAddedStyle;
  switch (style) {
    case CartAddedStyle.toast:
      showAppSnackBar(context, toastMessage, icon: toastIcon);
    case CartAddedStyle.overlay:
      showAddedOverlay(context, icon: icon, message: overlayMessage);
  }
}

/// Shows the centered, auto-dismissing check-mark cart overlay regardless of
/// the configured style. Prefer [showCartAddedFeedback] unless the caller has
/// already resolved that the overlay style is active.
void showCartAddedOverlay(BuildContext context) {
  showAddedOverlay(
    context,
    icon: Icons.check,
    message: 'Product added\nto the cart',
  );
}

/// Shows the centered, auto-dismissing overlay with [icon] above [message],
/// regardless of the configured style.
void showAddedOverlay(
  BuildContext context, {
  required IconData icon,
  required String message,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) =>
        _AddedOverlay(icon: icon, message: message, onDismiss: entry.remove),
  );
  overlay.insert(entry);
}

/// Animated overlay body: fades and scales a translucent card in, holds, then
/// fades out and calls [onDismiss] to remove its [OverlayEntry].
class _AddedOverlay extends StatefulWidget {
  const _AddedOverlay({
    required this.icon,
    required this.message,
    required this.onDismiss,
  });

  final IconData icon;
  final String message;
  final VoidCallback onDismiss;

  @override
  State<_AddedOverlay> createState() => _AddedOverlayState();
}

class _AddedOverlayState extends State<_AddedOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  static const _holdDuration = Duration(milliseconds: 950);
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _holdTimer = Timer(_holdDuration, _reverseThenDismiss);
  }

  Future<void> _reverseThenDismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    return IgnorePointer(
      child: Center(
        child: FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1).animate(curved),
            child: _card(context),
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: AppDimensions.cartAddedOverlaySize,
        minHeight: AppDimensions.cartAddedOverlaySize,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: AppDimensions.cartAddedCheckSize,
            height: AppDimensions.cartAddedCheckSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white,
                width: AppDimensions.swatchRingWidth,
              ),
            ),
            child: Icon(
              widget.icon,
              color: AppColors.white,
              size: AppDimensions.iconLg,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.white),
          ),
        ],
      ),
    );
  }
}
