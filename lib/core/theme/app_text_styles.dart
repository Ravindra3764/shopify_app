import 'package:flutter/material.dart';

/// Centralized typography scale.
///
/// Builds a [TextTheme] using the tenant `fontFamily` from `AppConfig`.
/// Feature widgets read styles via `Theme.of(context).textTheme.*`, never
/// construct `TextStyle(fontSize: ...)` inline.
abstract final class AppTextStyles {
  static TextTheme textTheme(String fontFamily) {
    return TextTheme(
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
