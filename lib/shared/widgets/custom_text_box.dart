import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';

/// Field visual/behavior variant.
enum _TextBoxVariant { standard, search, password }

/// Themed text input used across forms and search bars.
///
/// Three variants via named constructors — [CustomTextBox] (standard),
/// [CustomTextBox.search] (leading search icon), and [CustomTextBox.password]
/// (obscured with a visibility toggle). Supports an optional [label] above the
/// field, inline [errorText] (or a [validator] when inside a `Form`), and
/// [prefix]/[suffix] widgets. Styled entirely from the active theme.
///
/// ```dart
/// CustomTextBox(
///   label: 'City',
///   hintText: 'San Francisco',
///   controller: cityController,
///   validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
/// );
/// ```
class CustomTextBox extends StatefulWidget {
  /// Standard single-line text field.
  const CustomTextBox({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.prefix,
    this.suffix,
    this.enabled = true,
    this.autofillHints,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
  }) : _variant = _TextBoxVariant.standard;

  /// Search field with a leading magnifier icon.
  const CustomTextBox.search({
    super.key,
    this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.textInputAction = TextInputAction.search,
    this.enabled = true,
  }) : _variant = _TextBoxVariant.search,
       label = null,
       errorText = null,
       keyboardType = TextInputType.text,
       textCapitalization = TextCapitalization.none,
       validator = null,
       prefix = null,
       suffix = null,
       autofillHints = null,
       inputFormatters = null,
       maxLines = 1,
       minLines = null;

  /// Obscured password field with a show/hide toggle.
  const CustomTextBox.password({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.errorText,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.enabled = true,
    this.autofillHints,
  }) : _variant = _TextBoxVariant.password,
       keyboardType = TextInputType.visiblePassword,
       textCapitalization = TextCapitalization.none,
       prefix = null,
       suffix = null,
       inputFormatters = null,
       maxLines = 1,
       minLines = null;

  /// Controls the field's text.
  final TextEditingController? controller;

  /// Optional label rendered above the field.
  final String? label;

  /// Placeholder text shown when empty.
  final String? hintText;

  /// Explicit error message shown below the field (independent of [validator]).
  final String? errorText;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Validation callback used when the field is inside a `Form`.
  final FormFieldValidator<String>? validator;

  /// Optional leading widget (ignored by the search variant, which sets its
  /// own icon).
  final Widget? prefix;

  /// Optional trailing widget (ignored by the password variant, which sets its
  /// own toggle).
  final Widget? suffix;

  final bool enabled;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;

  /// Max lines the field grows to (1 = single line). Set higher with [minLines]
  /// for a multi-line input (e.g. a review body).
  final int maxLines;

  /// Min lines shown before scrolling; null uses [maxLines].
  final int? minLines;

  final _TextBoxVariant _variant;

  @override
  State<CustomTextBox> createState() => _CustomTextBoxState();
}

class _CustomTextBoxState extends State<CustomTextBox> {
  late bool _obscured = widget._variant == _TextBoxVariant.password;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final field = TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _obscured,
      maxLines: _obscured ? 1 : widget.maxLines,
      minLines: widget.minLines,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      autofillHints: widget.autofillHints,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.boxFill,
        hintText: widget.hintText,
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.hint),
        errorText: widget.errorText,
        errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.error),
        prefixIcon: _prefixIcon(),
        suffixIcon: _suffixIcon(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        enabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.primary),
        errorBorder: _border(AppColors.error),
        focusedErrorBorder: _border(AppColors.error),
        disabledBorder: _border(AppColors.disabled),
      ),
    );

    final label = widget.label;
    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelLarge?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        field,
      ],
    );
  }

  Widget? _prefixIcon() {
    if (widget._variant == _TextBoxVariant.search) {
      return const Icon(Icons.search, color: AppColors.textTertiary);
    }
    return widget.prefix;
  }

  Widget? _suffixIcon() {
    if (widget._variant == _TextBoxVariant.password) {
      return IconButton(
        icon: Icon(
          _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.textTertiary,
          size: AppDimensions.iconMd,
        ),
        onPressed: () => setState(() => _obscured = !_obscured),
      );
    }
    return widget.suffix;
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
    borderSide: BorderSide(color: color),
  );
}
