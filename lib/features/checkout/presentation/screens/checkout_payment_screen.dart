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

/// Completes payment on Shopify's hosted checkout page — never confirming an
/// order that wasn't actually paid.
///
/// Honors the `inAppWebviewCheckout` white-label flag:
/// * `true` — loads [checkoutUrl] in an in-app WebView and auto-detects the
///   thank-you redirect (Shopify's only trustworthy proof of a paid order),
///   then routes to the app's order-confirmed screen.
/// * `false` — hands off to the device browser for payment. Tapping "I've
///   completed my order" does **not** blindly confirm; it re-opens the same
///   [checkoutUrl] in a hidden WebView and inspects where Shopify routes it.
///   A completed checkout redirects to the thank-you page; an unpaid one shows
///   the payment form again — so we can verify payment server-side without the
///   Admin API. Completion clears the cart and routes to the confirmed screen;
///   an unpaid checkout surfaces an error.
class CheckoutPaymentScreen extends ConsumerStatefulWidget {
  const CheckoutPaymentScreen({required this.checkoutUrl, super.key});

  final String checkoutUrl;

  @override
  ConsumerState<CheckoutPaymentScreen> createState() =>
      _CheckoutPaymentScreenState();
}

class _CheckoutPaymentScreenState extends ConsumerState<CheckoutPaymentScreen> {
  WebViewController? _controller;

  /// Overlay spinner while the visible WebView (in-app mode) first loads.
  bool _loading = true;

  /// Guards against double-completion from overlapping navigation callbacks.
  bool _completed = false;

  /// True while re-checking a browser payment (external mode). Blocks the
  /// button and shows a "Verifying…" overlay; a page load that does *not* land
  /// on the thank-you page resolves this as "not paid".
  bool _verifying = false;

  bool get _inApp => ref.read(featureFlagsProvider).inAppWebviewCheckout;

  @override
  void initState() {
    super.initState();
    if (_inApp) {
      _controller = _buildController()
        ..loadRequest(Uri.parse(widget.checkoutUrl));
    } else {
      _loading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _launchExternal());
    }
  }

  WebViewController _buildController() {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            _log(url);
            if (_isOrderComplete(url)) _complete();
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _loading = false);
            if (_isOrderComplete(url)) {
              _complete();
              return;
            }
            // Verification reload settled on a non-thank-you page (the payment
            // form) → the checkout is still unpaid.
            if (_verifying && !_completed) _onNotPaid();
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
      );
  }

  void _log(String url) {
    if (kDebugMode) debugPrint('[checkout] webview url: $url');
  }

  Future<void> _launchExternal() async {
    final uri = Uri.parse(widget.checkoutUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// External mode: verify the browser payment actually went through by
  /// re-loading the checkout URL and letting the navigation delegate decide.
  Future<void> _verifyExternalPayment() async {
    if (_verifying || _completed) return;
    setState(() => _verifying = true);
    final controller = _controller ??= _buildController();
    await controller.loadRequest(Uri.parse(widget.checkoutUrl));
  }

  void _onNotPaid() {
    if (!mounted) return;
    setState(() => _verifying = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "We couldn't confirm your payment yet. "
          'Finish paying, then try again.',
        ),
      ),
    );
  }

  /// In-app WebView fallback: if auto-detection misses an SPA thank-you route,
  /// the shopper can tap "Done". We still verify against the WebView's *actual*
  /// current URL (same session as the payment) — never a blind confirmation.
  Future<void> _confirmInAppIfComplete() async {
    final controller = _controller;
    if (controller == null || _completed) return;
    final url = await controller.currentUrl();
    if (url != null && _isOrderComplete(url)) {
      await _complete();
    } else {
      _onNotPaid();
    }
  }

  /// Detects Shopify's genuine post-payment redirect — the sole proof the order
  /// was placed and paid (Shopify only routes here after a successful payment).
  ///
  /// Matches the thank-you page (classic `thank_you` and one-page checkout
  /// `thank-you`) and the authenticated order-status page. The order-status
  /// match requires the `key` query param so an account "Orders" list link
  /// (`/account/orders`) can never false-trigger completion.
  bool _isOrderComplete(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final path = uri.path.toLowerCase();
    if (path.contains('thank_you') || path.contains('thank-you')) return true;
    return path.contains('/orders/') && uri.queryParameters.containsKey('key');
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
    return CustomBackground(
      title: 'Payment',
      horizontalPadding: 0,
      contentTopPadding: 0,
      actions: _inApp
          ? [
              // Verified fallback for SPA thank-you routes the auto-detector
              // can miss. Checks the WebView's real current URL (same session
              // as payment) — never a blind confirmation.
              TextButton(
                onPressed: _confirmInAppIfComplete,
                child: Text(
                  'Done',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
                ),
              ),
            ]
          : null,
      child: _inApp ? _buildWebView() : _buildExternalPrompt(),
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
    final controller = _controller;
    return Stack(
      children: [
        // Off-screen WebView used only to verify the checkout state. It must be
        // in the tree to load on all platforms, but never shown to the user.
        if (controller != null)
          Offstage(
            child: SizedBox.square(
              child: WebViewWidget(controller: controller),
            ),
          ),
        Padding(
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
                isLoading: _verifying,
                onPressed: _verifyExternalPayment,
              ),
              const SizedBox(height: AppSpacing.md),
              CustomButton.outline(
                label: 'Reopen browser',
                onPressed: _verifying ? null : _launchExternal,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
