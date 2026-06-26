import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shopify_app/config/app_config.dart';
import 'package:shopify_app/core/error/shopify_exception.dart';

class ApiClient {
  /// Builds a client for [config]. Pass [dio] in tests to inject a mock.
  ApiClient({required AppConfig config, Dio? dio})
    : _dio = dio ?? _buildDio(config);

  final Dio _dio;

  static const Duration _timeout = Duration(seconds: 15);

  static Dio _buildDio(AppConfig config) {
    final dio = Dio(
      BaseOptions(
        baseUrl:
            'https://${config.shopifyDomain}'
            '/api/${config.storefrontApiVersion}/graphql.json',
        connectTimeout: _timeout,
        receiveTimeout: _timeout,
        headers: {
          'Content-Type': 'application/json',
          'X-Shopify-Storefront-Access-Token': config.storefrontAccessToken,
        },
      ),
    );
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
    return dio;
  }

  /// Throws [ShopifyException] on transport failure, a non-2xx status, an
  /// empty/malformed body, or a non-empty GraphQL `errors` array.
  Future<Map<String, dynamic>> query(
    String document, {
    Map<String, dynamic>? variables,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '',
        data: {'query': document, 'variables': variables ?? const {}},
      );

      final body = response.data;
      if (body == null) {
        throw ShopifyException(
          'Empty response from Storefront API',
          statusCode: response.statusCode,
        );
      }

      final errors = body['errors'];
      if (errors is List && errors.isNotEmpty) {
        throw ShopifyException(
          _joinGraphqlErrors(errors),
          statusCode: response.statusCode,
        );
      }

      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw ShopifyException(
          'Malformed Storefront response: missing "data"',
          statusCode: response.statusCode,
        );
      }
      return data;
    } on DioException catch (e) {
      throw ShopifyException(
        _mapDioError(e),
        statusCode: e.response?.statusCode,
        cause: e,
      );
    }
  }

  String _joinGraphqlErrors(List<dynamic> errors) {
    final messages = errors
        .whereType<Map<String, dynamic>>()
        .map((e) => e['message'])
        .whereType<String>()
        .where((m) => m.isNotEmpty)
        .toList();
    return messages.isEmpty ? 'GraphQL request failed' : messages.join(', ');
  }

  String _mapDioError(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Request timed out. Please check your connection.',
      DioExceptionType.connectionError => 'No internet connection.',
      DioExceptionType.badResponse =>
        'Storefront API error (${e.response?.statusCode}).',
      _ => 'A network error occurred.',
    };
  }
}
