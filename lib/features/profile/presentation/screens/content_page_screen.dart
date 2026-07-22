import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/profile/domain/profile_content.dart';
import 'package:shopify_app/features/profile/presentation/providers/content_providers.dart';
import 'package:shopify_app/shared/widgets/custom_background.dart';
import 'package:shopify_app/shared/widgets/empty_state_view.dart';
import 'package:shopify_app/shared/widgets/error_view.dart';
import 'package:shopify_app/shared/widgets/loading_shimmer.dart';

/// Read-only viewer for a static store [ProfileContent] entry (privacy
/// policy, terms, about, help). Fetches the copy from Shopify, renders it as
/// plain text, and shows an empty state when the merchant hasn't configured
/// that policy/page yet.
class ContentPageScreen extends ConsumerWidget {
  const ContentPageScreen({required this.content, super.key});

  /// Which static-content entry to display.
  final ProfileContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageAsync = ref.watch(profileContentProvider(content));
    return CustomBackground(
      title: content.title,
      child: pageAsync.when(
        data: (page) => page.hasContent
            ? _Body(text: page.body)
            : EmptyStateView(
                icon: Icons.article_outlined,
                message: '${content.title} is not available yet.',
              ),
        loading: () => const LoadingShimmer.article(),
        error: (e, _) => ErrorView(
          message: e is Failure ? e.message : 'Something went wrong.',
          onRetry: () => ref.invalidate(profileContentProvider(content)),
        ),
      ),
    );
  }
}

/// Scrollable, selectable plain-text body for a content page.
class _Body extends StatelessWidget {
  const _Body({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppDimensions.floatingNavClearance,
      ),
      children: [
        SelectableText(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: AppDimensions.bodyLineHeight,
          ),
        ),
      ],
    );
  }
}
