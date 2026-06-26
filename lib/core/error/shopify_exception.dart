/// Low-level failure raised by the Shopify transport layer.
///
/// Thrown by `ShopifyClient` for network errors, non-2xx responses, and
/// GraphQL `errors`. Repositories catch this and map it to a `Failure`
/// (see CLAUDE.md §6) — UI and notifiers never see it directly.
class ShopifyException implements Exception {
  const ShopifyException(this.message, {this.statusCode, this.cause});

  /// Human-readable summary, safe to surface after mapping to a `Failure`.
  final String message;

  /// HTTP status when the error came from a response; `null` for transport
  /// (timeout / no connection) and GraphQL-level errors.
  final int? statusCode;

  /// Underlying error (e.g. the originating `DioException`), for logging.
  final Object? cause;

  @override
  String toString() => 'ShopifyException($statusCode): $message';
}
