import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shopify_app/core/theme/app_colors.dart';

/// A soft, pastel background color sampled from a product image — used to tint
/// the card panel behind the product (Pinterest-style), so the card blends with
/// its photo instead of floating on a flat surface.
///
/// Keyed by image URL and cached for the session (`keepAlive`) so the palette
/// is generated once per image. On any failure the `AsyncValue` errors and
/// callers fall back to [AppColors.surface] — read it with
/// `ref.watch(productSwatchProvider(url)).maybeWhen(...)`.
final productSwatchProvider = FutureProvider.family<Color, String>((
  ref,
  imageUrl,
) async {
  ref.keepAlive();
  final palette = await PaletteGenerator.fromImageProvider(
    CachedNetworkImageProvider(imageUrl),
    size: const Size(_sampleSize, _sampleSize),
    maximumColorCount: _maxColors,
  );
  final base =
      palette.lightMutedColor?.color ??
      palette.mutedColor?.color ??
      palette.dominantColor?.color ??
      AppColors.surface;
  // Soften toward white so the panel stays a light pastel and text over/under
  // it stays readable regardless of how saturated the product photo is.
  return Color.lerp(base, AppColors.white, _whitenAmount) ?? base;
});

/// Downscaled sample size for palette generation — small keeps it cheap.
const double _sampleSize = 120;

/// Palette buckets to quantize into; fewer is faster and steadier.
const int _maxColors = 8;

/// How far to blend the sampled color toward white (0 = raw, 1 = white).
const double _whitenAmount = 0.35;
