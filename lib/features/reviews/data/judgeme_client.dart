import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Raised on any Judge.me transport/API error; the repository maps it to a
/// `Failure`. [statusCode] is null for a transport problem (timeout/offline).
class JudgeMeException implements Exception {
  const JudgeMeException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'JudgeMeException($statusCode): $message';
}

/// Thin transport for the Judge.me public REST API (`/api/v1`).
///
/// WARNING: this uses the tenant's **private** Judge.me token, shipped in the
/// client by explicit tenant choice — see `AppConfig.judgeMeApiToken`. Treat
/// the token as exposed. The read endpoints live on `api.judge.me`; review
/// creation lives on `judge.me`.
class JudgeMeClient {
  JudgeMeClient({
    required String shopDomain,
    required String apiToken,
    Dio? dio,
  }) : _shopDomain = shopDomain,
       _apiToken = apiToken,
       _dio = dio ?? _buildDio();

  static const _platform = 'shopify';
  static const _readBase = 'https://api.judge.me/api/v1';
  static const _writeBase = 'https://judge.me/api/v1';

  final String _shopDomain;
  final String _apiToken;
  final Dio _dio;

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(requestBody: true));
    }
    return dio;
  }

  Map<String, dynamic> get _auth => {
    'api_token': _apiToken,
    'shop_domain': _shopDomain,
  };

  /// Resolves a Shopify numeric product id to Judge.me's internal product id,
  /// or `null` when the product has no Judge.me record yet.
  Future<int?> productInternalId(String externalId) async {
    final data = await _get('$_readBase/products/-1', {
      ..._auth,
      'external_id': externalId,
    });
    final product = data['product'];
    if (product is Map && product['id'] is int) return product['id'] as int;
    return null;
  }

  /// One page of reviews for a Judge.me internal [productId].
  Future<Map<String, dynamic>> listReviews({
    required int productId,
    int page = 1,
    int perPage = 20,
  }) {
    return _get('$_readBase/reviews', {
      ..._auth,
      'product_id': productId,
      'page': page,
      'per_page': perPage,
    });
  }

  /// Creates a review. [externalProductId] is the Shopify numeric product id.
  /// Reviews created via the API are unpublished until moderated and cannot be
  /// marked verified.
  Future<void> createReview({
    required String externalProductId,
    required String name,
    required String email,
    required int rating,
    required String body,
    String? title,
  }) async {
    await _post('$_writeBase/reviews', {
      'shop_domain': _shopDomain,
      'platform': _platform,
      'id': externalProductId,
      'name': name,
      'email': email,
      'rating': rating,
      'body': body,
      if (title != null && title.isNotEmpty) 'title': title,
    });
  }

  Future<Map<String, dynamic>> _get(
    String url,
    Map<String, dynamic> query,
  ) async {
    try {
      final res = await _dio.get<dynamic>(url, queryParameters: query);
      return _asMap(res);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> _post(
    String url,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _dio.post<dynamic>(url, data: body);
      return _asMap(res);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Map<String, dynamic> _asMap(Response<dynamic> res) {
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    return const {};
  }

  JudgeMeException _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final apiMessage = data is Map && data['error'] is String
        ? data['error'] as String
        : null;
    return JudgeMeException(
      apiMessage ?? e.message ?? 'Judge.me request failed.',
      statusCode: status,
    );
  }
}
