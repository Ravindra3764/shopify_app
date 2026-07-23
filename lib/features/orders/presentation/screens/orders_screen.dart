import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/routing/app_routes.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/orders/presentation/providers/orders_providers.dart';
import 'package:shopify_app/shared/widgets/custom_background.dart';
import 'package:shopify_app/shared/widgets/empty_state_view.dart';
import 'package:shopify_app/shared/widgets/error_view.dart';
import 'package:shopify_app/shared/widgets/loading_shimmer.dart';
import 'package:shopify_app/shared/widgets/pull_to_refresh.dart';
import 'package:shopify_app/shopify/models/order.dart';

/// The signed-in customer's order history. Tapping an order opens its detail.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Loads the next page when the shopper nears the end of the list.
  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >=
        position.maxScrollExtent - AppDimensions.loadMoreThreshold) {
      ref.read(ordersProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(ordersProvider);
    await ref.read(ordersProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);
    return CustomBackground(
      title: 'My orders',
      child: ordersAsync.when(
        data: (data) => data.orders.isEmpty
            ? PullToRefresh(
                onRefresh: _refresh,
                scrollable: false,
                child: EmptyStateView(
                  icon: Icons.receipt_long_outlined,
                  message: "You haven't placed any orders yet.",
                  actionLabel: 'Start shopping',
                  onAction: () => context.go(AppRoutes.home),
                ),
              )
            : PullToRefresh(
                onRefresh: _refresh,
                child: ListView.separated(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(
                    top: AppSpacing.sm,
                    bottom: AppDimensions.floatingNavClearance,
                  ),
                  itemCount: data.orders.length + (data.hasMore ? 1 : 0),
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    if (index >= data.orders.length) {
                      return const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return _OrderCard(order: data.orders[index]);
                  },
                ),
              ),
        loading: () => const LoadingShimmer.orders(),
        error: (e, _) => ErrorView(
          message: e is Failure ? e.message : 'Something went wrong.',
          onRetry: () => ref.invalidate(ordersProvider),
        ),
      ),
    );
  }
}

/// A tappable order-summary card: number, date, status, item count + total.
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      onTap: () => context.push(AppRoutes.orderDetail, extra: order),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.name,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _StatusChip(label: order.fulfillmentLabel),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              DateFormat.yMMMMd().format(order.processedAt),
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.itemCount} '
                  '${order.itemCount == 1 ? 'item' : 'items'}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  order.total.formatted,
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small status pill (e.g. fulfillment status) shown on an order card.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: AppDimensions.chipFillAlpha),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
