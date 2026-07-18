import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';

/// Full-screen animated onboarding hint that teaches the double-tap-to-wishlist
/// gesture — a finger that taps twice over a heart that pops filled, with
/// expanding ripples. Dismisses on tap anywhere.
///
/// Show it once via [WishlistDoubleTapHint.show]; the caller owns the
/// "seen once" persistence.
///
/// ```dart
/// await WishlistDoubleTapHint.show(context, 'Double-tap to wishlist');
/// ```
class WishlistDoubleTapHint extends StatefulWidget {
  const WishlistDoubleTapHint({required this.message, super.key});

  final String message;

  /// Presents the hint as a dismissible full-screen overlay. Completes when the
  /// shopper dismisses it.
  static Future<void> show(BuildContext context, String message) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) => WishlistDoubleTapHint(message: message),
      transitionBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    );
  }

  @override
  State<WishlistDoubleTapHint> createState() => _WishlistDoubleTapHintState();
}

class _WishlistDoubleTapHintState extends State<WishlistDoubleTapHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  // The two "taps" land at these points of the loop; ripples and the heart
  // fill are timed to them.
  static const _tap1 = 0.12;
  static const _tap2 = 0.32;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      behavior: HitTestBehavior.opaque,
      child: ColoredBox(
        color: AppColors.black.withValues(alpha: 0.72),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimensions.hintMaxWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: AppDimensions.hintStageSize,
                      height: AppDimensions.hintStageSize,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) => _Stage(t: _controller.value),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Tap anywhere to continue',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The animated cluster: ripples, a heart that pops filled on the second tap,
/// and a finger that presses twice. [t] is the loop progress in `0..1`.
class _Stage extends StatelessWidget {
  const _Stage({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        _ripple(_phase(t, _WishlistDoubleTapHintState._tap1)),
        _ripple(_phase(t, _WishlistDoubleTapHintState._tap2)),
        _heart(),
        _finger(),
      ],
    );
  }

  /// How long (in loop fraction) a ripple takes to expand and fade after its
  /// tap fires.
  static const _rippleSpan = 0.35;

  /// A tap's local progress in `0..1` over `_rippleSpan` after `start`, clamped
  /// so it only animates in that window.
  double _phase(double t, double start) =>
      ((t - start) / _rippleSpan).clamp(0.0, 1.0);

  Widget _ripple(double phase) {
    if (phase <= 0 || phase >= 1) return const SizedBox.shrink();
    final scale = 0.3 + phase * 1.2;
    return Opacity(
      opacity: (1 - phase) * 0.6,
      child: Container(
        width: AppDimensions.hintRippleSize * scale,
        height: AppDimensions.hintRippleSize * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: AppSpacing.xs / 2),
        ),
      ),
    );
  }

  Widget _heart() {
    // Fills between the two taps, then pops slightly on the second.
    final filled = t >= _WishlistDoubleTapHintState._tap1;
    final pop = _phase(t, _WishlistDoubleTapHintState._tap2);
    final scale = 1 + (pop < 0.5 ? pop : 1 - pop) * 0.4;
    return Transform.scale(
      scale: filled ? scale : 1,
      child: Icon(
        filled ? Icons.favorite : Icons.favorite_border,
        size: AppDimensions.hintHeartSize,
        color: filled ? AppColors.error : AppColors.white,
      ),
    );
  }

  Widget _finger() {
    // Presses down (smaller + offset) briefly at each tap.
    final press1 = _pressAt(_WishlistDoubleTapHintState._tap1);
    final press2 = _pressAt(_WishlistDoubleTapHintState._tap2);
    final press = press1 > press2 ? press1 : press2;
    return Transform.translate(
      offset: Offset(AppSpacing.lg, AppSpacing.lg + press * AppSpacing.sm),
      child: Transform.scale(
        scale: 1 - press * 0.18,
        child: const Icon(
          Icons.touch_app,
          size: AppDimensions.hintFingerSize,
          color: AppColors.white,
        ),
      ),
    );
  }

  /// Press intensity `0..1` peaking right at [tapCentre].
  double _pressAt(double tapCentre) {
    const half = 0.06;
    final d = (t - tapCentre).abs();
    return d >= half ? 0.0 : 1 - d / half;
  }
}
