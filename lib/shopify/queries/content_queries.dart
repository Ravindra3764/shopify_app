// GraphQL documents for static store content shown under Profile → More.

/// Store privacy policy (Settings → Policies). `null` fields if unset.
const String kPrivacyPolicyQuery = '''
query PrivacyPolicy {
  shop {
    privacyPolicy { title body url }
  }
}
''';

/// Store terms of service (Settings → Policies). `null` if unset.
const String kTermsOfServiceQuery = '''
query TermsOfService {
  shop {
    termsOfService { title body url }
  }
}
''';

/// A content page by handle (Online Store → Pages), e.g. `about-us`.
/// Returns `null` if no page with that handle exists / is published.
const String kContentPageQuery = r'''
query ContentPage($handle: String!) {
  page(handle: $handle) { title body onlineStoreUrl }
}
''';
