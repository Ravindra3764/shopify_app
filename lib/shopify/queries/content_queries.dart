// GraphQL documents for static store content shown under Profile → More.

/// Bodies of every store policy (Settings → Policies). A policy is treated as
/// "set" only when its body has real text (Storefront returns a non-null node
/// with a title even for a blank policy), so this fetches the body to decide
/// which menu tiles to show.
const String kShopPolicyLinksQuery = '''
query ShopPolicyLinks {
  shop {
    privacyPolicy { body }
    termsOfService { body }
    refundPolicy { body }
    shippingPolicy { body }
    subscriptionPolicy { body }
  }
}
''';

/// Builds a query for a single `shop.<field>` policy body. [field] is always a
/// fixed `ProfileContent.policyField` constant (never user input).
String shopPolicyQuery(String field) =>
    'query ShopPolicy { shop { $field { title body url } } }';

/// A content page by handle (Online Store → Pages), e.g. `about-us`.
/// Returns `null` if no page with that handle exists / is published.
const String kContentPageQuery = r'''
query ContentPage($handle: String!) {
  page(handle: $handle) { title body onlineStoreUrl }
}
''';
