import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/features/profile/data/content_repository_impl.dart';
import 'package:shopify_app/features/profile/domain/content_repository.dart';
import 'package:shopify_app/features/profile/domain/profile_content.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/providers/shopify_providers.dart';
import 'package:shopify_app/shopify/models/shop_content_page.dart';

/// Static-content repository, wired to the Storefront `ApiClient`.
final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => ContentRepositoryImpl(ref.watch(apiClientProvider)),
);

/// The store policies the merchant has actually configured, as the set of
/// [ProfileContent] policy entries to surface in the Profile → More menu.
///
/// Shop-wide and rarely changing, so kept alive for the session.
final availablePoliciesProvider =
    AsyncNotifierProvider<AvailablePoliciesNotifier, Set<ProfileContent>>(
      AvailablePoliciesNotifier.new,
    );

/// Maps the Storefront policy field names that are set to their
/// [ProfileContent] entries; rethrows `Failure` for `AsyncValue.error`.
class AvailablePoliciesNotifier extends AsyncNotifier<Set<ProfileContent>> {
  @override
  Future<Set<ProfileContent>> build() async {
    ref.keepAlive();
    final repo = ref.watch(contentRepositoryProvider);
    final result = await repo.getAvailablePolicyFields();
    return result.fold(
      (fields) => ProfileContent.policies
          .where((c) => fields.contains(c.policyField))
          .toSet(),
      (Failure failure) => throw failure,
    );
  }
}

/// Loads the [ShopContentPage] for a [ProfileContent] entry, keyed per entry.
///
/// Content is shop-wide and rarely changes, so each entry is kept alive for
/// the session once loaded rather than refetched on every screen open.
final profileContentProvider =
    AsyncNotifierProvider.family<
      ProfileContentNotifier,
      ShopContentPage,
      ProfileContent
    >(ProfileContentNotifier.new);

/// Fetches one [ProfileContent] entry via [ContentRepository]; rethrows
/// `Failure` for `AsyncValue.error`. Policies read `shop.<policyField>`;
/// About/Help resolve their page handle from tenant config.
class ProfileContentNotifier
    extends FamilyAsyncNotifier<ShopContentPage, ProfileContent> {
  @override
  Future<ShopContentPage> build(ProfileContent content) async {
    ref.keepAlive();
    final repo = ref.watch(contentRepositoryProvider);
    final config = ref.watch(appConfigProvider);

    final result = await switch (content) {
      final c when c.isPolicy => repo.getPolicy(c.policyField!),
      ProfileContent.about => repo.getPage(config.aboutPageHandle ?? ''),
      ProfileContent.help => repo.getPage(config.helpPageHandle ?? ''),
      // Unreachable: every entry is a policy or a page.
      _ => repo.getPage(''),
    };
    return result.fold((page) => page, (Failure failure) => throw failure);
  }
}
