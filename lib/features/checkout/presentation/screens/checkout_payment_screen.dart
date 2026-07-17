import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/routing/app_routes.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/cart/presentation/providers/cart_providers.dart';
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
            if (_isOrderComplete(url)) _complete();
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
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

  Future<void> _launchExternal() async {
    final uri = Uri.parse(widget.checkoutUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Matches Shopify's post-payment URLs (thank-you / order-status pages).
  bool _isOrderComplete(String url) {
    final lower = url.toLowerCase();
    return lower.contains('thank_you') ||
        lower.contains('thank-you') ||
        lower.contains('/orders/') ||
        lower.contains('order-status');
  }

  Future<void> _complete() async {
    if (_completed) return;
    _completed = true;
    await ref.read(cartProvider.notifier).clearCart();
    if (mounted) context.go(AppRoutes.orderConfirmed);
  }

  @override
  Widget build(BuildContext context) {
    final inApp = ref.watch(featureFlagsProvider).inAppWebviewCheckout;
    return CustomBackground(
      title: 'Payment',
      horizontalPadding: 0,
      contentTopPadding: 0,
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
