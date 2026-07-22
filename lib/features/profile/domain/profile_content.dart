/// The static content entries listed under Profile → More.
///
/// Two kinds:
/// - **Store policies** (Settings → Policies) carry a [policyField] naming the
///   Storefront `shop.<field>` they read. Only the policies a merchant has
///   actually set are shown (see `availablePoliciesProvider`).
/// - **Content pages** (Online Store → Pages) have a `null` [policyField]; they
///   resolve their handle from tenant config on `AppConfig`.
enum ProfileContent {
  /// Privacy policy — `shop.privacyPolicy`.
  privacyPolicy('Privacy policy', policyField: 'privacyPolicy'),

  /// Terms of service — `shop.termsOfService`.
  terms('Terms & conditions', policyField: 'termsOfService'),

  /// Return & refund policy — `shop.refundPolicy`.
  refund('Return & refund policy', policyField: 'refundPolicy'),

  /// Shipping policy — `shop.shippingPolicy`.
  shipping('Shipping policy', policyField: 'shippingPolicy'),

  /// Purchase-options cancellation policy — `shop.subscriptionPolicy`.
  subscription('Cancellation policy', policyField: 'subscriptionPolicy'),

  /// About-us page — `page(handle: aboutPageHandle)`.
  about('About us'),

  /// Help & support page — `page(handle: helpPageHandle)`.
  help('Help & support');

  const ProfileContent(this.title, {this.policyField});

  /// Screen title / menu label for this entry.
  final String title;

  /// Storefront `shop.<field>` name for a store policy, or `null` for a
  /// content page.
  final String? policyField;

  /// Whether this entry is a store policy (vs. a content page).
  bool get isPolicy => policyField != null;

  /// All store-policy entries, in menu order.
  static Iterable<ProfileContent> get policies =>
      values.where((c) => c.isPolicy);
}
