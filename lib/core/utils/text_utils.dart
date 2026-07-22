/// Strips HTML tags from Shopify rich-text fields (e.g. `descriptionHtml`),
/// collapsing whitespace left behind.
String stripHtmlTags(String html) {
  return html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp('<[^>]*>'), '')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n\s*\n+'), '\n\n')
      .trim();
}

/// Converts Shopify rich-text HTML (store policies, content pages) into
/// readable plain text: block-level closers become paragraph breaks, list
/// items get a bullet, and common HTML entities are decoded — then
/// [stripHtmlTags] removes the remaining markup. Use for long-form copy
/// (privacy policy, terms, about) where paragraph structure matters.
String htmlToPlainText(String html) {
  final withStructure = html
      .replaceAll(RegExp('<li[^>]*>', caseSensitive: false), '• ')
      .replaceAll(
        RegExp(
          '</(p|div|li|ul|ol|h[1-6]|tr|table|blockquote)>',
          caseSensitive: false,
        ),
        '\n\n',
      );
  return _decodeHtmlEntities(stripHtmlTags(withStructure));
}

/// Decodes the handful of HTML entities Shopify rich text commonly emits.
String _decodeHtmlEntities(String text) {
  return text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'");
}
