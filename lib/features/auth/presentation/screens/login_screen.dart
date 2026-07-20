import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/routing/app_routes.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:shopify_app/features/auth/presentation/widgets/auth_form_scaffold.dart';
import 'package:shopify_app/features/auth/presentation/widgets/auth_validators.dart';
import 'package:shopify_app/shared/widgets/app_snack_bar.dart';
import 'package:shopify_app/shared/widgets/custom_button.dart';
import 'package:shopify_app/shared/widgets/custom_text_box.dart';

/// Email + password sign-in. Signs the shopper in via [authProvider], then
/// pops back to wherever sign-in was requested from (Profile, gated checkout).
/// Links to registration and password recovery.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final failure = await ref
        .read(authProvider.notifier)
        .login(email: _email.text.trim(), password: _password.text);
    if (!mounted || failure == null) return;
    showAppSnackBar(context, failure.message);
  }

  @override
  Widget build(BuildContext context) {
    // Sign-in succeeded elsewhere in the graph → dismiss back to the origin.
    ref.listen<bool>(isAuthenticatedProvider, (_, isAuthed) {
      if (isAuthed && context.canPop()) context.pop();
    });
    final isLoading = ref.watch(authProvider).isLoading;
    final textTheme = Theme.of(context).textTheme;

    return AuthFormScaffold(
      title: 'Sign in',
      formKey: _formKey,
      children: [
        Text(
          'Welcome back',
          style: textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Sign in to your account to continue.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        CustomTextBox(
          controller: _email,
          label: 'Email',
          hintText: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          validator: validateEmail,
        ),
        const SizedBox(height: AppSpacing.md),
        CustomTextBox.password(
          controller: _password,
          label: 'Password',
          hintText: 'Your password',
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          validator: validateRequiredPassword,
          onSubmitted: (_) => _submit(),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push(AppRoutes.forgotPassword),
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        CustomButton.primary(
          label: 'Sign in',
          isLoading: isLoading,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account?",
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.register),
              child: const Text('Register'),
            ),
          ],
        ),
      ],
    );
  }
}
