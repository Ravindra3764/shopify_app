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
