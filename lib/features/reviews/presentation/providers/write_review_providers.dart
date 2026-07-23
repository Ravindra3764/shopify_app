import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/features/reviews/domain/review_draft.dart';
import 'package:shopify_app/features/reviews/presentation/providers/reviews_providers.dart';

/// Drives a single review submission. `AsyncData` = idle/submitted,
/// `AsyncLoading` = in flight, `AsyncError` = last submit failed. On success it
/// invalidates `reviewsProvider(productId)` so the list refetches.
final writeReviewProvider =
    AutoDisposeAsyncNotifierProvider<WriteReviewNotifier, void>(
      WriteReviewNotifier.new,
    );

/// Notifier backing [writeReviewProvider].
class WriteReviewNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Submits [draft]. Returns `true` on success. Failures are surfaced via
  /// [state] as `AsyncError` carrying the `Failure`.
  Future<bool> submit(ReviewDraft draft) async {
    state = const AsyncLoading();
    final result = await ref.read(reviewRepositoryProvider).submitReview(draft);
    return result.fold(
      (_) {
        state = const AsyncData(null);
        ref.invalidate(reviewsProvider(draft.productId));
        return true;
      },
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
    );
  }
}
