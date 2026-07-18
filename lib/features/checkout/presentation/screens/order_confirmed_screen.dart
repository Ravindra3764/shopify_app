import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/routing/app_routes.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/checkout/domain/order_confirmation.dart';
import 'package:shopify_app/shared/widgets/custom_button.dart';
import 'package:shopify_app/shared/widgets/custom_cached_image.dart';
import 'package:shopify_app/shopify/models/cart_line.dart';
import 'package:shopify_app/shopify/models/money.dart';

/// Terminal success screen shown after payment completes. Animates a success
/// badge in, then reveals the order summary ([confirmation]) captured just
/// before the cart was cleared. Offers a route back to shopping.
class OrderConfirmedScreen extends StatefulWidget {
  const OrderConfirmedScreen({this.confirmation, super.key});

  final OrderConfirmation? confirmation;

  @override
  State<OrderConfirmedScreen> createState() => _OrderConfirmedScreenState();
}

class _OrderConfirmedScreenState extends State<OrderConfirmedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Animation<double> _badge = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.55, curve: Curves.elasticOut),
  );

  late final Animation<double> _content = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.4, 1, curve: Curves.easeOut),
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(_content);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final order = widget.confirmation;
    final email = order?.email;
    final subtitle = email != null
        ? 'Thank you! A confirmation email is on its way to $email.'
        : 'Thank you for your purchase.';

    return PopScope(
      // The cart is already cleared; back should return to shopping, not the
      // dead payment screen.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.home);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: ScaleTransition(
                  scale: _badge,
                  child: Container(
                    width: AppDimensions.successBadgeSize,
                    height: AppDimensions.successBadgeSize,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.white,
                      size: AppSpacing.xxl,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FadeTransition(
                opacity: _content,
                child: SlideTransition(
                  position: _slide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Order confirmed',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (order != null) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _ItemsCard(lines: order.lines),
                        const SizedBox(height: AppSpacing.md),
                        _TotalsCard(order: order),
                        if (order.address != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          _InfoCard(
                            title: 'Delivering to',
                            body:
                                '${order.address!.fullName}\n'
                                '${order.address!.formatted}',
                          ),
                        ],
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      CustomButton.primary(
                        label: 'Continue shopping',
                        onPressed: () => context.go(AppRoutes.home),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.lines});

  final List<CartLine> lines;

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

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomCachedImage(
          imageUrl: line.image?.url ?? '',
          placeholderName: line.productTitle,
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
                line.productTitle,
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              if (line.optionsSummary.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  line.optionsSummary,
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
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.order});

  final OrderConfirmation order;

  String get _shipping {
    final s = order.shipping;
    if (s == null) return 'Free';
    return s.amount <= 0 ? 'Free' : s.formatted;
  }

  String get _tax =>
      order.tax?.formatted ??
      Money(amount: 0, currencyCode: order.subtotal.currencyCode).formatted;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          _Row(label: 'Subtotal', value: order.subtotal.formatted),
          const SizedBox(height: AppSpacing.sm),
          _Row(label: 'Shipping', value: _shipping),
          const SizedBox(height: AppSpacing.sm),
          _Row(label: 'Tax', value: _tax),
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
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
          ),
        ],
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
