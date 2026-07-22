/// The static content entries listed under Profile → More.
///
/// Each maps to a Storefront source: [privacyPolicy] and [terms] come from
/// Settings → Policies; [about] and [help] come from Online Store → Pages
/// (their handles are tenant config on `AppConfig`).
enum ProfileContent {
  /// Privacy policy — `shop.privacyPolicy`.
  privacyPolicy('Privacy policy'),

  /// Terms of service — `shop.termsOfService`.
  terms('Terms & conditions'),

  /// About-us page — `page(handle: aboutPageHandle)`.
  about('About us'),

  /// Help & support page — `page(handle: helpPageHandle)`.
  help('Help & support');

  const ProfileContent(this.title);

  /// Screen title / menu label for this entry.
  final String title;
}
