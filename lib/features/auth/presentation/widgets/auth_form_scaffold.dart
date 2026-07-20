import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/shared/widgets/custom_background.dart';

/// Shared page shell for the auth screens (login / register / recover).
///
/// Renders a [CustomBackground] with [title] and a scrollable, keyboard-safe
/// [Form] laid out in a single column of [children]. Keeps the three auth
/// screens visually consistent.
class AuthFormScaffold extends StatelessWidget {
  const AuthFormScaffold({
    required this.title,
    required this.formKey,
    required this.children,
    super.key,
  });

  /// App-bar title.
  final String title;

  /// Key for the wrapped [Form].
  final GlobalKey<FormState> formKey;

  /// Form fields and actions, stacked vertically.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return CustomBackground(
      title: title,
      child: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: children,
        ),
      ),
    );
  }
}
