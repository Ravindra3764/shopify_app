import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:shopify_app/features/auth/presentation/widgets/auth_form_scaffold.dart';
import 'package:shopify_app/features/auth/presentation/widgets/auth_message.dart';
import 'package:shopify_app/features/auth/presentation/widgets/auth_validators.dart';
import 'package:shopify_app/shared/widgets/custom_button.dart';
import 'package:shopify_app/shared/widgets/custom_text_box.dart';

/// New-customer registration. Creates the account and signs the shopper in via
/// [authProvider], then pops back to the origin (which unwinds the login screen
/// too, since both listen for the authenticated transition).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  /// Last registration error, shown inline in red.
  String? _error;

  /// Set when the account was created but needs email verification — shown
  /// inline in green (informational, not an error).
  String? _info;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _info = null;
    });
    final failure = await ref
        .read(authProvider.notifier)
        .register(
          email: _email.text.trim(),
          password: _password.text,
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
        );
    if (!mounted || failure == null) return;
    // Account created but the store requires email verification before login.
    if (failure is EmailVerificationRequired) {
      _formKey.currentState?.reset();
      setState(() => _info = failure.message);
      return;
    }
    setState(() => _error = failure.message);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(isAuthenticatedProvider, (_, isAuthed) {
      if (isAuthed && context.canPop()) context.pop();
    });
    final isLoading = ref.watch(authProvider).isLoading;
    final textTheme = Theme.of(context).textTheme;

    return AuthFormScaffold(
      title: 'Create account',
      formKey: _formKey,
      children: [
        Text(
          'Join us',
          style: textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Create an account to check out faster and track orders.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        CustomTextBox(
          controller: _firstName,
          label: 'First name',
          hintText: 'Jane',
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.givenName],
        ),
        const SizedBox(height: AppSpacing.md),
        CustomTextBox(
          controller: _lastName,
          label: 'Last name',
          hintText: 'Doe',
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.familyName],
        ),
        const SizedBox(height: AppSpacing.md),
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
          hintText: 'At least 5 characters',
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          validator: validateNewPassword,
          onSubmitted: (_) => _submit(),
        ),
        if (_info != null) ...[
          AuthMessage(_info!, isError: false),
          const SizedBox(height: AppSpacing.md),
        ],
        if (_error != null) ...[
          AuthMessage(_error!),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.lg),
        CustomButton.primary(
          label: 'Create account',
          isLoading: isLoading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
