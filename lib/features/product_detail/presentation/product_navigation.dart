import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/routing/app_routes.dart';
import 'package:shopify_app/features/product_detail/domain/product_peek_args.dart';
import 'package:shopify_app/shopify/models/product.dart';

/// Opens the product at [index] within [products], passing the whole list as
/// [ProductPeekArgs] so the Blinkit-style sheet can swipe between siblings.
/// The classic full-page detail ignores the extra, so this is safe everywhere.
void openProductFromList(
  BuildContext context,
  List<Product> products,
  int index,
) {
  context.push(
    AppRoutes.productDetailPath(products[index].handle),
    extra: ProductPeekArgs(
      handles: [for (final p in products) p.handle],
      initialIndex: index,
    ),
  );
}
