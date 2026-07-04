import 'package:flutter/material.dart';

/// Best-effort [Color] for a Shopify color-option value (e.g. `Obsidian
/// Noir`, `Ivory`) — the Storefront API has no swatch-hex field, so this
/// matches common color-family keywords. Falls back to a neutral grey.
Color colorForSwatchName(String name) {
  final value = name.toLowerCase();
  for (final entry in _swatchColors.entries) {
    if (value.contains(entry.key)) return entry.value;
  }
  return const Color(0xFF9E9E9E);
}

const Map<String, Color> _swatchColors = {
  'black': Color(0xFF1A1A1A),
  'noir': Color(0xFF1A1A1A),
  'onyx': Color(0xFF1A1A1A),
  'white': Color(0xFFF2F0EC),
  'ivory': Color(0xFFF2F0EC),
  'cream': Color(0xFFF2E9D8),
  'beige': Color(0xFFE8DCC8),
  'tan': Color(0xFFC9A876),
  'sand': Color(0xFFD8C6A3),
  'khaki': Color(0xFFBFB38F),
  'grey': Color(0xFF545453),
  'gray': Color(0xFF545453),
  'charcoal': Color(0xFF3A3A38),
  'silver': Color(0xFFC0C0C0),
  'brown': Color(0xFF6B4A34),
  'chocolate': Color(0xFF4A2E1F),
  'camel': Color(0xFFC19A6B),
  'red': Color(0xFFB3261E),
  'burgundy': Color(0xFF5E1A26),
  'maroon': Color(0xFF5E1A26),
  'pink': Color(0xFFE8B4C0),
  'rose': Color(0xFFC98A9C),
  'blush': Color(0xFFEAC6CE),
  'orange': Color(0xFFD9793D),
  'rust': Color(0xFFA3512A),
  'yellow': Color(0xFFE0C341),
  'mustard': Color(0xFFC9A227),
  'gold': Color(0xFFC9A94A),
  'green': Color(0xFF4C6B4F),
  'olive': Color(0xFF6B6B3E),
  'sage': Color(0xFF9CAF88),
  'emerald': Color(0xFF1E5C4A),
  'blue': Color(0xFF3A5F8A),
  'navy': Color(0xFF1F2D4A),
  'teal': Color(0xFF2E6B6B),
  'purple': Color(0xFF5C3A6B),
  'lavender': Color(0xFFB6A8D1),
  'multi': Color(0xFF9E9E9E),
};
