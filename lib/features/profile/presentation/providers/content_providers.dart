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
/// `Failure` for `AsyncValue.error`. About/Help resolve their page handle
/// from tenant config.
class ProfileContentNotifier
    extends FamilyAsyncNotifier<ShopContentPage, ProfileContent> {
  @override
  Future<ShopContentPage> build(ProfileContent content) async {
    ref.keepAlive();
    final repo = ref.watch(contentRepositoryProvider);
    final config = ref.watch(appConfigProvider);

    final result = await switch (content) {
      ProfileContent.privacyPolicy => repo.getPrivacyPolicy(),
      ProfileContent.terms => repo.getTermsOfService(),
      ProfileContent.about => repo.getPage(config.aboutPageHandle ?? ''),
      ProfileContent.help => repo.getPage(config.helpPageHandle ?? ''),
    };
    return result.fold((page) => page, (Failure failure) => throw failure);
  }
}
