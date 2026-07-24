import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shopify_app/core/theme/app_colors.dart';

/// A soft, pastel background color sampled from a product image — used to tint
/// the card panel behind the product (Pinterest-style), so the card blends with
/// its photo instead of floating on a flat surface.
///
/// Keyed by image URL: the palette is generated once per image, then the result
/// is cached for [_cacheTtl] after its last listener drops (so a re-scroll is
/// instant) and disposed after that to bound memory — instead of caching every
/// image seen all session. On any failure the `AsyncValue` errors and callers
/// fall back to [AppColors.surface] — read with
/// `ref.watch(productSwatchProvider(url)).maybeWhen(...)`.
///
/// Pass an already-sized (thumbnail) URL so palette generation samples a small
/// image, not the full-resolution original.
final productSwatchProvider = FutureProvider.autoDispose.family<Color, String>((
  ref,
  imageUrl,
) async {
  // Keep the computed color briefly after the card scrolls off, then release.
  final link = ref.keepAlive();
  final timer = Timer(_cacheTtl, link.close);
  ref.onDispose(timer.cancel);

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

/// How long a computed swatch stays cached after its last listener drops.
const Duration _cacheTtl = Duration(minutes: 3);
