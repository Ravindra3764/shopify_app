import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';

/// Wraps content in a brand-themed pull-to-refresh gesture.
///
/// Pass [onRefresh] a callback that re-fetches (typically invalidate a provider
/// and await its `.future`); the spinner shows until the future completes.
///
/// When [child] is already a scrollable (`ListView`, `GridView`, …), give it
/// `physics: const AlwaysScrollableScrollPhysics()` so short content can still
/// be pulled, and leave [scrollable] `true`. When [child] is *not* scrollable
/// (an empty/error view), set [scrollable] to `false` and it's wrapped in a
/// viewport-filling scroll view so the pull still works.
///
/// ```dart
/// PullToRefresh(onRefresh: _refresh, child: ListView(...));
/// PullToRefresh(
///   onRefresh: _refresh, scrollable: false, child: EmptyStateView(...));
/// ```
class PullToRefresh extends StatelessWidget {
  const PullToRefresh({
    required this.onRefresh,
    required this.child,
    this.scrollable = true,
    super.key,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  /// Whether [child] is already scrollable. `false` wraps it in a viewport-
  /// filling scroll view so non-scrollable content can still be pulled.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: scrollable
          ? child
          : LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: child,
                ),
              ),
            ),
    );
  }
}
