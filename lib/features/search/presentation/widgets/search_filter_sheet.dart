import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/search/domain/search_filters.dart';
import 'package:shopify_app/shared/widgets/custom_button.dart';
import 'package:shopify_app/shared/widgets/custom_text_box.dart';

/// Bottom sheet to refine search results: sort order, in-stock only, and a
/// price range. Returns the chosen [SearchFilters] via `Navigator.pop`, or
/// `null` if dismissed.
///
/// ```dart
/// final next = await showModalBottomSheet<SearchFilters>(
///   context: context,
///   isScrollControlled: true,
///   builder: (_) => SearchFilterSheet(initial: current),
/// );
/// ```
class SearchFilterSheet extends StatefulWidget {
  const SearchFilterSheet({required this.initial, super.key});

  final SearchFilters initial;

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  late SearchSort _sort = widget.initial.sort;
  late bool _inStockOnly = widget.initial.inStockOnly;
  late final _minController = TextEditingController(
    text: widget.initial.minPrice?.toString() ?? '',
  );
  late final _maxController = TextEditingController(
    text: widget.initial.maxPrice?.toString() ?? '',
  );

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _sort = SearchSort.relevance;
      _inStockOnly = false;
      _minController.clear();
      _maxController.clear();
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      SearchFilters(
        sort: _sort,
        inStockOnly: _inStockOnly,
        minPrice: double.tryParse(_minController.text.trim()),
        maxPrice: double.tryParse(_maxController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter & Sort',
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(onPressed: _reset, child: const Text('Reset')),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Sort by',
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            RadioGroup<SearchSort>(
              groupValue: _sort,
              onChanged: (v) => setState(() => _sort = v ?? _sort),
              child: Column(
                children: [
                  for (final option in SearchSort.values)
                    RadioListTile<SearchSort>(
                      value: option,
                      title: Text(option.label),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                ],
              ),
            ),
            const Divider(color: AppColors.divider),
            SwitchListTile(
              value: _inStockOnly,
              onChanged: (v) => setState(() => _inStockOnly = v),
              title: const Text('In stock only'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Price range',
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: CustomTextBox(
                    controller: _minController,
                    hintText: 'Min',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: CustomTextBox(
                    controller: _maxController,
                    hintText: 'Max',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            CustomButton.primary(label: 'Apply', onPressed: _apply),
          ],
        ),
      ),
    );
  }
}
