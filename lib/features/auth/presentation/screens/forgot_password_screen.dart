import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:shopify_app/features/auth/presentation/widgets/auth_form_scaffold.dart';
import 'package:shopify_app/features/auth/presentation/widgets/auth_validators.dart';
import 'package:shopify_app/shared/widgets/app_snack_bar.dart';
import 'package:shopify_app/shared/widgets/custom_button.dart';
import 'package:shopify_app/shared/widgets/custom_text_box.dart';
import 'package:shopify_app/shared/widgets/empty_state_view.dart';

/// Password recovery. Sends a Shopify reset email; the reset itself completes
/// via the emailed web link, so on success the screen just confirms and lets
/// the shopper return to sign-in.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  /// Set once Shopify has accepted the reset request.
  bool _sent = false;

  /// True only while the recover request is in flight.
  bool _sending = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    final failure = await ref
        .read(authProvider.notifier)
        .recover(_email.text.trim());
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = failure == null;
    });
    if (failure != null) showAppSnackBar(context, failure.message);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AuthFormScaffold(
      title: 'Reset password',
      formKey: _formKey,
      children: _sent
          ? [
              EmptyStateView(
                icon: Icons.mark_email_read_outlined,
                message: 'Check your email for a link to reset your password.',
                actionLabel: 'Back to sign in',
                onAction: () => context.pop(),
              ),
            ]
          : [
              Text(
                'Forgot your password?',
                style: textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                "Enter your email and we'll send you a reset link.",
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              CustomTextBox(
                controller: _email,
                label: 'Email',
                hintText: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                validator: validateEmail,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.lg),
              CustomButton.primary(
                label: 'Send reset link',
                isLoading: _sending,
                onPressed: _submit,
              ),
            ],
    );
  }
}
