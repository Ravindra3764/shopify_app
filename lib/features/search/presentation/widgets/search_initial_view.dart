import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/search/presentation/providers/search_providers.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/shared/widgets/empty_state_view.dart';

/// Shown before a query is entered: recent searches (persisted) and the
/// tenant's popular search chips. Falls back to a prompt when both are empty.
class SearchInitialView extends ConsumerWidget {
  const SearchInitialView({required this.onTermSelected, super.key});

  /// Called with the chosen term when a chip is tapped.
  final void Function(String term) onTermSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(searchHistoryProvider);
    final popular = ref.watch(appConfigProvider).popularSearches;

    if (recent.isEmpty && popular.isEmpty) {
      return const EmptyStateView(
        icon: Icons.search,
        message: 'Search for products by name, brand, or type.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (recent.isNotEmpty) ...[
          _SectionHeader(
            title: 'Recent searches',
            action: 'Clear',
            onAction: () => ref.read(searchHistoryProvider.notifier).clear(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final term in recent)
                InputChip(
                  label: Text(term),
                  onPressed: () => onTermSelected(term),
                  onDeleted: () =>
                      ref.read(searchHistoryProvider.notifier).remove(term),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (popular.isNotEmpty) ...[
          const _SectionHeader(title: 'Popular searches'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final term in popular)
                ActionChip(
                  label: Text(term),
                  onPressed: () => onTermSelected(term),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
        ),
        if (action != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}
