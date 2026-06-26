import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';

/// Network image with disk caching, placeholder, and graceful fallback.
///
/// Caches via `cached_network_image`. Shows a neutral skeleton box while
/// loading; on a non-fetchable URL or load error it renders a fallback — the
/// first letter of [placeholderName] when given, otherwise a plain tile. Pass
/// [borderRadius] to clip the corners.
///
/// ```dart
/// CustomCachedImage(
///   imageUrl: product.featuredImage?.url ?? '',
///   placeholderName: product.title,
///   borderRadius: AppDimensions.radiusMd,
/// );
/// ```
class CustomCachedImage extends StatelessWidget {
  const CustomCachedImage({
    required this.imageUrl,
    super.key,
    this.placeholderName,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String imageUrl;

  /// When set, the fallback shows this value's first letter.
  final String? placeholderName;
  final double? height;
  final double? width;
  final BoxFit fit;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    // Only http(s) URLs are fetchable; relative paths crash the codec.
    final url = imageUrl.trim();
    final isFetchable = url.startsWith('http://') || url.startsWith('https://');

    final Widget image = isFetchable
        ? CachedNetworkImage(
            imageUrl: url,
            fit: fit,
            height: height,
            width: width,
            placeholder: (_, _) => _Placeholder(height: height, width: width),
            errorWidget: (_, _, _) => _Placeholder(
              height: height,
              width: width,
              name: placeholderName,
            ),
          )
        : _Placeholder(height: height, width: width, name: placeholderName);

    if (borderRadius == null) return image;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius!),
      child: image,
    );
  }
}

/// Fallback tile: brand-tinted box, optionally with the [name]'s first letter.
class _Placeholder extends StatelessWidget {
  const _Placeholder({this.height, this.width, this.name});

  final double? height;
  final double? width;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name?.trim();
    final hasInitial = trimmed != null && trimmed.isNotEmpty;
    return ColoredBox(
      color: AppColors.shimmerBase,
      child: SizedBox(
        height: height,
        width: width,
        child: hasInitial
            ? Center(
                child: Text(
                  trimmed[0].toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
