import 'package:intl/intl.dart';
import 'package:shopify_app/core/utils/json_parse.dart';

/// Shopify money value — an [amount] paired with its [currencyCode].
///
/// Always carry both; never reduce a price to a bare double.
class Money {
  const Money({required this.amount, required this.currencyCode});

  /// Builds from a Storefront `MoneyV2` (`{amount, currencyCode}`).
  factory Money.fromJson(Map<String, dynamic> json) {
    return Money(
      amount: parseDouble(json, 'amount', model: _model),
      currencyCode: parseString(
        json,
        'currencyCode',
        fallback: 'USD',
        model: _model,
      ),
    );
  }

  static const _model = 'Money';

  final double amount;
  final String currencyCode;

  /// Whether this represents a real, payable amount.
  bool get isPositive => amount > 0;

  /// Localized currency string, e.g. `$150.00`.
  String get formatted =>
      NumberFormat.simpleCurrency(name: currencyCode).format(amount);
}
