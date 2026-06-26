import 'package:shopify_app/core/error/shopify_exception.dart';

/// Domain-level error surfaced to notifiers and the UI.
///
/// Repositories map low-level `ShopifyException`s into one of these via
/// [Failure.fromShopify]; widgets read [message] to render an `ErrorView`.
sealed class Failure implements Exception {
  const Failure(this.message);

  factory Failure.fromShopify(ShopifyException e) {
    // No status code means a transport problem (timeout / no connection).
    if (e.statusCode == null) return NetworkFailure(e.message);
    return ShopifyFailure(e.message, statusCode: e.statusCode);
  }

  final String message;
}

/// Connectivity / timeout failure (no HTTP response received).
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Shopify responded with an error status or GraphQL `errors`.
final class ShopifyFailure extends Failure {
  const ShopifyFailure(super.message, {this.statusCode});

  final int? statusCode;
}

/// Anything not otherwise classified.
final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}
