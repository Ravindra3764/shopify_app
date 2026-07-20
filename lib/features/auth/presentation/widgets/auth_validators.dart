// Form-field validators shared across the auth screens. Each returns `null`
// when valid, or a shopper-facing error string otherwise.

/// Matches a basic `local@domain.tld` shape — enough to catch typos before
/// hitting Shopify, which is the real authority on validity.
final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Shopify requires customer passwords to be at least 5 characters.
const int _minPasswordLength = 5;

/// Validates a required email address.
String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Enter your email.';
  if (!_emailPattern.hasMatch(email)) return 'Enter a valid email.';
  return null;
}

/// Validates a non-empty password (sign-in — no length rule, Shopify decides).
String? validateRequiredPassword(String? value) {
  if (value == null || value.isEmpty) return 'Enter your password.';
  return null;
}

/// Validates a new password meets Shopify's minimum length (sign-up).
String? validateNewPassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Choose a password.';
  if (password.length < _minPasswordLength) {
    return 'Use at least $_minPasswordLength characters.';
  }
  return null;
}
