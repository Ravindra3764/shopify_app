import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shopify_app/core/routing/app_routes.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/reviews/domain/product_reviews_args.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/shared/widgets/custom_background.dart';
import 'package:shopify_app/shared/widgets/custom_cached_image.dart';
import 'package:shopify_app/shopify/models/money.dart';
import 'package:shopify_app/shopify/models/order.dart';
import 'package:shopify_app/shopify/models/order_line.dart';

/// Read-only detail of a placed [Order]: status, purchased lines, price
/// breakdown, and shipping address. Rendered from an already-loaded [Order]
/// (passed as route `extra`) — no extra fetch.
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final address = order.shippingAddress;
    return CustomBackground(
      title: order.name,
      child: ListView(
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppDimensions.floatingNavClearance,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat.yMMMMd().format(order.processedAt),
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              _StatusText(
                label: order.fulfillmentLabel,
                financial: order.financialLabel,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel('Items (${order.itemCount})'),
          _ItemsCard(lines: order.lines),
          const SizedBox(height: AppSpacing.md),
          const _SectionLabel('Payment'),
          _TotalsCard(order: order),
          if (address != null) ...[
            const SizedBox(height: AppSpacing.md),
            const _SectionLabel('Shipping to'),
            _InfoCard(body: '${address.fullName}\n${address.formatted}'),
          ],
        ],
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText({required this.label, this.financial});

  final String label;
  final String? financial;

  @override
  Widget build(BuildContext context) {
    final text = financial == null ? label : '$label · $financial';
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.lines});

  final List<OrderLine> lines;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            _LineRow(line: lines[i]),
            if (i < lines.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Divider(
                  color: AppColors.divider,
                  height: AppDimensions.hairline,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _LineRow extends ConsumerWidget {
  const _LineRow({required this.line});

  final OrderLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final productId = line.productId;
    // The shopper bought this in this order, so no purchase gate — just needs
    // review submission enabled and a resolvable product.
    final canReview =
        ref.watch(featureFlagsProvider).reviewSubmissionEnabled &&
        productId != null &&
        productId.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomCachedImage(
              imageUrl: line.image?.url ?? '',
              placeholderName: line.title,
              height: AppDimensions.orderThumbSize,
              width: AppDimensions.orderThumbSize,
              borderRadius: AppDimensions.radiusSm,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.title,
                    style: textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (line.variantTitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      line.variantTitle!,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Qty ${line.quantity}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              line.lineTotal.formatted,
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (canReview)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.push(
                AppRoutes.productReviewWrite,
                extra: ProductReviewsArgs(
                  productId: productId,
                  productTitle: line.title,
                ),
              ),
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Write a review'),
            ),
          ),
      ],
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.order});

  final Order order;

  String _shipping() {
    final s = order.shipping;
    if (s == null || s.amount <= 0) return 'Free';
    return s.formatted;
  }

  @override
  Widget build(BuildContext context) {
    final zero = Money(amount: 0, currencyCode: order.total.currencyCode);
    return _Card(
      child: Column(
        children: [
          if (order.subtotal != null) ...[
            _Row(label: 'Subtotal', value: order.subtotal!.formatted),
            const SizedBox(height: AppSpacing.sm),
          ],
          _Row(label: 'Shipping', value: _shipping()),
          const SizedBox(height: AppSpacing.sm),
          _Row(label: 'Tax', value: (order.tax ?? zero).formatted),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(
              color: AppColors.border,
              height: AppDimensions.hairline,
            ),
          ),
          _Row(label: 'Total', value: order.total.formatted, emphasized: true),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Text(
        body,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = emphasized
        ? textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          )
        : textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
