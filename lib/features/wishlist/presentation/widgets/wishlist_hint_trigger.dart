import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/features/wishlist/presentation/widgets/wishlist_double_tap_hint.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/providers/storage_providers.dart';

/// Shows the one-time "double-tap to wishlist" onboarding hint on first launch,
/// then never again. Renders nothing itself — drop it into any screen's tree.
///
/// Gated on both the wishlist feature and the hint flag; the copy comes from
/// the tenant's `AppConfig.wishlistHintText`.
class WishlistHintTrigger extends ConsumerStatefulWidget {
  const WishlistHintTrigger({super.key});

  @override
  ConsumerState<WishlistHintTrigger> createState() =>
      _WishlistHintTriggerState();
}

class _WishlistHintTriggerState extends ConsumerState<WishlistHintTrigger> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowHint());
  }

  void _maybeShowHint() {
    if (!mounted) return;
    final flags = ref.read(featureFlagsProvider);
    if (!flags.wishlistEnabled || !flags.wishlistDoubleTapHintEnabled) return;

    // In "always" mode the hint replays every launch; otherwise it shows once
    // and is remembered as seen.
    if (!flags.wishlistHintAlways) {
      final storage = ref.read(onboardingStorageProvider);
      if (storage.wishlistHintSeen()) return;
      unawaited(storage.markWishlistHintSeen());
    }

    unawaited(
      WishlistDoubleTapHint.show(
        context,
        ref.read(appConfigProvider).wishlistHintText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
