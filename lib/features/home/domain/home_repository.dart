import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/features/home/domain/home_data.dart';

/// Loads the data backing the home screen.
// ignore: one_member_abstracts
abstract interface class HomeRepository {
  /// Fetches hero banners and collections (with products) in one call.
  Future<Result<HomeData, Failure>> getHome();
}
