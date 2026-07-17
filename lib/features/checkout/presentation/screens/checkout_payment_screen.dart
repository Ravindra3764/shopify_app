import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/routing/app_routes.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/cart/presentation/providers/cart_providers.dart';
import 'package:shopify_app/features/checkout/domain/order_confirmation.dart';
import 'package:shopify_app/features/checkout/presentation/providers/checkout_providers.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/shared/widgets/custom_background.dart';
import 'package:shopify_app/shared/widgets/custom_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Completes payment on Shopify's hosted checkout page.
///
/// Honors the `inAppWebviewCheckout` white-label flag: `true` loads the
/// [checkoutUrl] in an in-app WebView and auto-detects order completion;
/// `false` hands off to the device browser and offers a manual "I've completed
/// my order" confirmation. Either way, completion clears the cart and routes to
/// the order-confirmed screen.
class CheckoutPaymentScreen extends ConsumerStatefulWidget {
  const CheckoutPaymentScreen({required this.checkoutUrl, super.key});

  final String checkoutUrl;

  @override
  ConsumerState<CheckoutPaymentScreen> createState() =>
      _CheckoutPaymentScreenState();
}

class _CheckoutPaymentScreenState extends ConsumerState<CheckoutPaymentScreen> {
  WebViewController? _controller;
  bool _loading = true;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    final inApp = ref.read(featureFlagsProvider).inAppWebviewCheckout;
    if (inApp) {
      _initWebView();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _launchExternal());
    }
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            _log(url);
            if (_isOrderComplete(url)) _complete();
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          // Shopify's checkout is a single-page app: the thank-you page often
          // loads via client-side routing (history.pushState) without a real
          // navigation, so `onNavigationRequest` never sees it. `onUrlChange`
          // catches those in-page URL changes.
          onUrlChange: (change) {
            final url = change.url;
            if (url == null) return;
            _log(url);
            if (_isOrderComplete(url)) _complete();
          },
          onNavigationRequest: (request) {
            if (_isOrderComplete(request.url)) {
              _complete();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  void _log(String url) {
    if (kDebugMode) debugPrint('[checkout] webview url: $url');
  }

  Future<void> _launchExternal() async {
    final uri = Uri.parse(widget.checkoutUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Matches Shopify's post-payment URLs (thank-you / order-status pages).
  /// `thank` covers both `thank_you` and `thank-you`; the order/status paths
  /// cover the newer one-page checkout redirect.
  bool _isOrderComplete(String url) {
    final lower = url.toLowerCase();
    return lower.contains('thank') ||
        lower.contains('/orders/') ||
        lower.contains('order-status') ||
        lower.contains('order_status') ||
        lower.contains('/post-purchase');
  }

  Future<void> _complete() async {
    if (_completed) return;
    _completed = true;
    // Snapshot the paid cart before clearing it, so the confirmation screen
    // can show the order details.
    final checkout = ref.read(checkoutProvider).valueOrNull;
    final confirmation = checkout == null
        ? null
        : OrderConfirmation(
            lines: checkout.cart.lines,
            subtotal: checkout.cart.subtotal,
            total: checkout.cart.total,
            email: checkout.email,
            address: checkout.selectedAddress,
            shipping: checkout.cart.selectedShipping,
            tax: checkout.cart.tax,
          );
    await ref.read(cartProvider.notifier).clearCart();
    if (mounted) context.go(AppRoutes.orderConfirmed, extra: confirmation);
  }

  @override
  Widget build(BuildContext context) {
    final inApp = ref.watch(featureFlagsProvider).inAppWebviewCheckout;
    return CustomBackground(
      title: 'Payment',
      horizontalPadding: 0,
      contentTopPadding: 0,
      actions: inApp
          ? [
              // Fallback: if auto-detection misses the thank-you page, the
              // shopper can confirm a completed order manually.
              TextButton(
                onPressed: _complete,
                child: Text(
                  'Done',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
                ),
              ),
            ]
          : null,
      child: inApp ? _buildWebView() : _buildExternalPrompt(),
    );
  }

  Widget _buildWebView() {
    final controller = _controller;
    if (controller == null) return const SizedBox.shrink();
    return Stack(
      children: [
        WebViewWidget(controller: controller),
        if (_loading)
          const ColoredBox(
            color: AppColors.background,
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildExternalPrompt() {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.open_in_browser,
            size: AppSpacing.xxl,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Complete your payment in the browser, then return here.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          CustomButton.primary(
            label: "I've completed my order",
            onPressed: _complete,
          ),
          const SizedBox(height: AppSpacing.md),
          CustomButton.outline(
            label: 'Reopen browser',
            onPressed: _launchExternal,
          ),
        ],
      ),
    );
  }
}
