import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/features/home/data/home_repository_impl.dart';
import 'package:shopify_app/features/home/domain/home_data.dart';
import 'package:shopify_app/features/home/domain/home_repository.dart';
import 'package:shopify_app/providers/shopify_providers.dart';

/// Home repository, wired to the Storefront `ApiClient`.
final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepositoryImpl(ref.watch(apiClientProvider)),
);

/// Loads and exposes the home screen payload as an [AsyncValue].
final homeProvider = AsyncNotifierProvider<HomeNotifier, HomeData>(
  HomeNotifier.new,
);

/// Fetches [HomeData] via [HomeRepository]; rethrows a `Failure` so the UI can
/// render it through `AsyncValue.error`.
class HomeNotifier extends AsyncNotifier<HomeData> {
  @override
  Future<HomeData> build() async {
    final repo = ref.watch(homeRepositoryProvider);
    final result = await repo.getHome();
    return result.fold((data) => data, (failure) => throw failure);
  }

  /// Re-fetches from scratch (e.g. pull-to-refresh / retry).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(homeRepositoryProvider).getHome();
      return result.fold((data) => data, (failure) => throw failure);
    });
  }
}
