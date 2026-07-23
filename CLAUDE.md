# CLAUDE.md

Guidance for Claude (and developers) working in this repository. Read this before writing code. The rules here are **mandatory**, not suggestions — they exist so any session produces consistent, production-grade output without re-explanation.

---

## 0. Branching (do this first, always)

**Never work on `main`.** Before starting *any* task — feature, fix, refactor, or docs — create and switch to a related branch off `main`:

```bash
git checkout main && git pull
git checkout -b <type>/<short-kebab-desc>   # e.g. feature/promo-offers, fix/cart-zero-total
```

Branch prefixes: `feature/`, `fix/`, `refactor/`, `chore/`, `docs/`. Do all work and commits on that branch; open a PR into `main`. If you notice work has begun on `main`, branch immediately (uncommitted changes carry over on checkout) before committing.

---

## 1. Project Overview

- **App**: Multi-tenant, white-label e-commerce app built in Flutter. One codebase, reskinned per client (the "tenant") via configuration — never via per-client code forks.
- **Backend**: Shopify **Storefront API** (GraphQL). We do **not** use the Admin API from the app. Storefront access tokens are public-scope tokens and are safe to ship in the client, but they are still treated as per-tenant config (see §3).
- **State management**: **Riverpod, no code generation.** Hand-write providers with `Provider` / `NotifierProvider` / `AsyncNotifierProvider`. The standard async primitive is a class extending **`AsyncNotifier`**; mutable UI state extends **`Notifier`**. No `@riverpod`, no `riverpod_generator`, no `build_runner`. See §7.
- **Models / config**: plain immutable classes (`final` fields + `const` constructor + hand-written `fromJson` / `fromEnv`). **No freezed, no json_serializable, no codegen anywhere in this repo.**
- **Tenant config**: loaded from a bundled **`.env`** file via `flutter_dotenv` (not JSON assets, not `--dart-define`). See §3.
- **Targets**: iOS + Android. Code must follow Flutter/Dart best practices and pass `flutter analyze` with zero issues under `very_good_analysis`.
- **Dart/Flutter**: Dart SDK `^3.10.4`. Use modern language features (records, patterns, sealed classes, `switch` expressions).

> The scaffold described below is **already in place** (`lib/core/theme`, `lib/config`, `lib/providers`, `lib/bootstrap.dart`, `lib/app.dart`). Extend it; follow the established patterns exactly.

---

## 2. Architecture & Folder Structure

### Approach: Feature-first, with layered separation inside each feature

We use **feature-first** (not layer-first) because a white-label e-commerce app grows by *feature* (wishlist, reviews, search), and features are toggled per tenant. Feature-first keeps everything for a feature co-located, makes feature flags trivial to reason about, and lets a whole feature be added/removed without touching unrelated folders.

Inside each feature we still separate **data / domain / presentation** so business logic stays out of widgets and the backend stays swappable.

```
lib/
├── main.dart                  # Thin: void main() => bootstrap();
├── bootstrap.dart             # Loads .env → AppConfig, AppColors.init, ProviderScope override
├── app.dart                   # Root MaterialApp, theme wiring (router added later)
│
├── core/                      # Cross-cutting, feature-agnostic
│   ├── constants/             # App-wide constants (durations, keys, regex)
│   ├── error/                 # Failure types, exception → Failure mapping
│   ├── network/              # ApiClient (Dio Storefront transport), interceptors
│   ├── routing/               # GoRouter config, route names, guards
│   ├── theme/                 # AppTheme, AppColors, AppSpacing, AppTextStyles (§4)
│   ├── utils/                 # Pure helpers, extensions, formatters
│   └── result/                # Result/Either type for typed error handling
│
├── config/                    # White-label configuration (§3)
│   ├── app_config.dart        # AppConfig — plain immutable, AppConfig.fromEnv
│   ├── feature_flags.dart     # FeatureFlags — plain, FeatureFlags.fromEnv
│   └── config_repository.dart # Loads .env via flutter_dotenv, builds AppConfig
│
├── shopify/                   # Storefront API layer (§6) — client is core/network/api_client.dart
│   ├── queries/               # One file per domain: products, collections, cart…
│   ├── mutations/             # cart_create, cart_lines_add, customer_login…
│   └── models/                # Storefront DTOs (plain immutable + fromJson)
│
├── features/
│   ├── auth/
│   │   ├── data/              # Repositories impl, data sources, DTO mapping
│   │   ├── domain/            # Entities, repository interfaces, use cases (if needed)
│   │   └── presentation/      # Screens, widgets, providers for this feature
│   │       ├── providers/     # Riverpod notifiers scoped to auth
│   │       ├── screens/
│   │       └── widgets/
│   ├── home/
│   ├── product_listing/
│   ├── product_detail/
│   ├── cart/
│   ├── checkout/
│   ├── orders/
│   ├── profile/
│   ├── search/
│   └── wishlist/
│
├── shared/
│   └── widgets/               # Reusable UI library (§5)
│
└── providers/                 # Global/app-level providers only
    ├── config_providers.dart  # appConfigProvider, featureFlagsProvider
    ├── shopify_providers.dart  # apiClientProvider, repository providers
    └── router_provider.dart
```

**Provider placement rule**: feature-specific providers live in `features/<feature>/presentation/providers/`. Only truly global/shared providers live in top-level `providers/`. Do not dump everything into `providers/`.

### Naming conventions

| Thing | Convention | Example |
|---|---|---|
| Files / folders | `snake_case` | `product_card.dart`, `product_listing/` |
| Classes / enums / typedefs | `PascalCase` | `ProductCard`, `CartRepository` |
| Members, locals, params | `camelCase` | `unitPrice`, `addToCart()` |
| Constants | `camelCase` (lowerCamel, Dart style) | `defaultPageSize` |
| Riverpod providers | `<noun>Provider` | `cartProvider`, `appConfigProvider` |
| Notifier class | `<Noun>Notifier` → exposes `<noun>Provider` | `class CartNotifier` → `final cartProvider` |
| Repository interface / impl | `XRepository` / `XRepositoryImpl` | `CartRepository` / `CartRepositoryImpl` |
| Model / entity | noun, no suffix | `Product`, `CartLine` |
| GraphQL DTO (if distinct from entity) | `XDto` | `ProductDto` |
| Screens | `XScreen` | `CartScreen` |

---

## 3. White-Label Configuration System

The same binary reskins per tenant **without changing any feature code**. All tenant-specific values live in the bundled **`.env`** file and flow through a single immutable `AppConfig`.

### `.env` (active tenant — swap this file per tenant)

```env
APP_NAME=Acme Store
FONT_FAMILY=Monorope
SHOPIFY_DOMAIN=acme.myshopify.com
STOREFRONT_ACCESS_TOKEN=replace_me
STOREFRONT_API_VERSION=2025-01
PRIMARY_COLOR=#086C4C        # only the brand primary varies per tenant
SECONDARY_COLOR=#625B71
ACCENT_COLOR=#7D5260
LOGO_ASSET=assets/images/logo.png
WISHLIST_ENABLED=true
REVIEWS_ENABLED=false
SEARCH_ENABLED=true
GUEST_CHECKOUT_ENABLED=false
```

`.env` is declared under `flutter: assets:` in `pubspec.yaml` so it is bundled.

### Single source of config (plain immutable, no codegen)

```dart
// config/app_config.dart
class AppConfig {
  const AppConfig({
    required this.appName,
    required this.fontFamily,
    required this.shopifyDomain,
    required this.storefrontAccessToken,
    required this.storefrontApiVersion,
    required this.primaryColorHex,
    required this.secondaryColorHex,
    required this.accentColorHex,
    required this.logoAsset,
    required this.features,
  });

  /// Builds from parsed .env entries; throws StateError (fail-fast) if a
  /// required key is missing.
  factory AppConfig.fromEnv(Map<String, String> env) { /* required(...) */ }

  final String appName;
  // ... final fields ...
  final FeatureFlags features;
}
```

`FeatureFlags` is likewise plain, with `FeatureFlags.fromEnv(env)` reading `"true"`/`"false"`.

### Loading at startup

Config is loaded **before `runApp`** by `ConfigRepository` (wraps `flutter_dotenv`), then injected via a Riverpod override so it is synchronously available everywhere — no `AsyncValue` for config reads.

```dart
// bootstrap.dart
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await const ConfigRepository().load(); // dotenv.load → AppConfig.fromEnv
  AppColors.init(config);                               // brand colors → palette (§4)
  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const App(),
    ),
  );
}

// providers/config_providers.dart  (plain providers, no @riverpod)
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('overridden in bootstrap()'),
);
final featureFlagsProvider =
    Provider<FeatureFlags>((ref) => ref.watch(appConfigProvider).features);
```

### Multiple tenants

- Each tenant has its own `.env` (and its own launcher icon / app id). Build a tenant by swapping `.env` (e.g. per Flutter flavor or a CI copy step) before `flutter build`.
- App name, brand primary color, Shopify store, logo, and feature flags differ **only** through `.env` → `AppConfig`.
- **Rule**: never branch feature logic on tenant name (`if (tenant == 'acme')`). Branch only on `FeatureFlags` or config values.

---

## 4. Theming & Spacing Standards

All visual constants come from `core/theme/`. **No magic numbers, no hardcoded colors, no inline `TextStyle` in feature widgets.**

### Dynamic theme from config

```dart
// core/theme/app_theme.dart
abstract final class AppTheme {
  static ThemeData light(AppConfig config) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.fromHex(config.primaryColorHex),
      secondary: AppColors.fromHex(config.secondaryColorHex),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: config.fontFamily,
      textTheme: AppTextStyles.textTheme(config.fontFamily),
    );
  }
}
```

The router/app wires it:

```dart
// app.dart
final config = ref.watch(appConfigProvider);
return MaterialApp.router(
  theme: AppTheme.light(config),
  // ...
);
```

### Spacing — `AppSpacing`

```dart
// core/theme/app_spacing.dart
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}
```

Use `EdgeInsets.all(AppSpacing.md)`, `SizedBox(height: AppSpacing.sm)`. **Never** `EdgeInsets.all(16)`.

### Typography — `AppTextStyles`

Defines the type scale (display/headline/title/body/label) once, returns a `TextTheme`. Feature widgets read styles via `Theme.of(context).textTheme.titleMedium`, never construct `TextStyle(fontSize: 18, ...)` inline.

### Hard rules

- Colors → `Theme.of(context).colorScheme.*` or `AppColors` only.
- Spacing/sizes → `AppSpacing` / `AppDimensions` only.
- Text → `Theme.of(context).textTheme.*` only.
- A literal number in `EdgeInsets`, `SizedBox`, `Radius`, etc. is a review-blocking violation unless it is `0` or comes from `AppSpacing`.

---

## 5. Shared Widget Library (`shared/widgets/`)

Reusable, theme-driven, documented components. Every widget:
- accepts styling from theme/config — **no hardcoded colors/spacing/text styles**;
- has a doc comment (`///`) explaining purpose, key props, and a usage line;
- exposes loading/disabled/error states where relevant;
- is covered by a widget test (§8).

Required components (non-exhaustive):

| Widget | Variants / states |
|---|---|
| `CustomTextBox` | `default`, `search`, `password` (obscure toggle), error text, prefix/suffix |
| `CustomButton` | `primary`, `secondary`, `outline`; `isLoading`, `disabled` |
| `ProductCard` | `grid`, `list` variants |

> **Square product cards — always use `WishlistProductCard`.** Whenever you render a square/grid product card anywhere in the app (home rows, collection grid, wishlist, search results, related products…), use `features/wishlist/presentation/widgets/wishlist_product_card.dart`, **not** the bare `ProductCard`. It wraps `ProductCard` with the wishlist heart + double-tap-to-save behavior wired to providers, and falls back to a plain card when the tenant has wishlist disabled — so every card in the app has identical, consistent gesture/heart behavior for free. Do not re-wire `isWishlisted`/`onWishlistToggle`/`onDoubleTap` by hand at call sites.
| `CartItemTile` | qty stepper, remove action |
| `PriceTag` | compare-at strikethrough, currency from Shopify money |
| `RatingStars` | read-only + interactive |
| `SectionHeader` | title + optional "See all" action |
| `EmptyStateView` | icon, message, optional CTA |
| `LoadingShimmer` | skeleton placeholders — **one variant per layout**: `.card`, `.grid`, `.list`, `.productDetail`. Shape must match the real content it replaces, not a generic box. Every async screen reuses these for its `loading:` state (see §7). |
| `ErrorView` | message + retry callback |

Example contract:

```dart
/// Primary call-to-action button.
///
/// Renders a filled/outlined button styled from the active theme. Shows a
/// spinner and blocks taps while [isLoading]. Pass [onPressed] = null to disable.
///
/// ```dart
/// CustomButton.primary(label: 'Add to cart', isLoading: adding, onPressed: addToCart)
/// ```
class CustomButton extends StatelessWidget {
  const CustomButton.prim
  ary({ /* ... */ });
  const CustomButton.outline({ /* ... */ });
  // ...
}
```

---

## 6. Shopify Storefront API Integration

### Client wrapper

`ApiClient` (Dio-based) wraps the GraphQL transport, injects the Storefront token + API version from `AppConfig`, and is the only place HTTP/GraphQL details live. It lives at `core/network/api_client.dart`.

```dart
// core/network/api_client.dart
class ApiClient {
  ApiClient({required AppConfig config, Dio? dio}) // DI for tests
      : _dio = dio ?? _buildDio(config);

  // _buildDio sets baseUrl = https://{shopifyDomain}/api/{version}/graphql.json
  // headers:
  //   'Content-Type': 'application/json'
  //   'X-Shopify-Storefront-Access-Token': config.storefrontAccessToken
  // kDebugMode → LogInterceptor.

  Future<Map<String, dynamic>> query(String document, {Map<String, dynamic>? variables}) {
    // POST {query, variables}; returns `data`.
    // Throws ShopifyException on transport error, non-2xx, empty/malformed
    // body, or non-empty GraphQL `errors` → mapped to Failure in repository.
  }
}

// providers/shopify_providers.dart  (plain provider, no codegen)
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(config: ref.watch(appConfigProvider)),
);
```

### Query/mutation file convention

One file per domain under `shopify/queries/` and `shopify/mutations/`:

```
shopify/queries/products_queries.dart      // products list, product by handle
shopify/queries/collections_queries.dart
shopify/queries/cart_queries.dart
shopify/queries/customer_queries.dart
shopify/mutations/cart_mutations.dart      // cartCreate, cartLinesAdd, cartLinesUpdate
shopify/mutations/customer_mutations.dart  // customerAccessTokenCreate, …
```

GraphQL documents are `const String` named after the operation (`kGetProductsQuery`, `kCartLinesAddMutation`).

### Models

- DTOs in `shopify/models/` are **plain immutable classes** (`final` fields + `const` constructor + hand-written `fromJson`). **No freezed, no json_serializable.** Add a `copyWith` by hand where mutation-by-copy is needed.
- Map Shopify money correctly (`amount` + `currencyCode`); don't store prices as raw doubles without currency.

### Repository pattern (mandatory)

UI and notifiers **never** call `ApiClient` or GraphQL directly. They depend on a repository **interface** in `domain/`; the `data/` layer implements it against Shopify and maps DTO → entity → `Failure`.

```dart
// features/cart/domain/cart_repository.dart
abstract interface class CartRepository {
  Future<Result<Cart, Failure>> getCart(String cartId);
  Future<Result<Cart, Failure>> addLine(String cartId, String variantId, int qty);
}

// features/cart/data/cart_repository_impl.dart
class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl(this._client);
  final ApiClient _client;
  // calls _client.query, maps responses, catches ShopifyException → Failure
}
```

This keeps the backend swappable — Shopify could be replaced without touching presentation.

---

## 7. State Management Rules (Riverpod)

### Standard patterns

| Use case | Provider type |
|---|---|
| Async data from a repository (products, cart, orders) | hand-written class extending **`AsyncNotifier`** / `FamilyAsyncNotifier`, exposed via `AsyncNotifierProvider(.family)` |
| Synchronous derived/config values | plain `Provider` |
| Mutable local UI state (form, filters, selected tab) | hand-written class extending **`Notifier`**, exposed via `NotifierProvider` |
| Plain dependency (client, repo) | plain `Provider` |

**No code generation.** Hand-write providers — no `@riverpod`, no `riverpod_generator`, no `build_runner`. `StateNotifier` is legacy — **do not** introduce it; use `Notifier`/`AsyncNotifier`. Use `.autoDispose` explicitly where disposal is wanted; `ref.keepAlive()` when caching is needed.

```dart
// features/product_listing/presentation/providers/products_provider.dart
class ProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    final repo = ref.watch(productRepositoryProvider);
    final result = await repo.getProducts();
    return result.fold((products) => products, (failure) => throw failure);
  }

  Future<void> loadMore() async { /* ... */ }
}

final productsProvider =
    AsyncNotifierProvider<ProductsNotifier, List<Product>>(ProductsNotifier.new);
```

### UI consumption — `AsyncValue.when`

Widgets render async state with `.when` (or pattern matching). **No raw `try/catch`, no `FutureBuilder`, no manual loading bools in widgets.**

```dart
final productsAsync = ref.watch(productsProvider);
return productsAsync.when(
  data: (products) => ProductGrid(products: products),
  loading: () => const LoadingShimmer.grid(),
  error: (e, _) => ErrorView(
    message: (e as Failure).message,
    onRetry: () => ref.invalidate(productsProvider),
  ),
);
```

### Hard rules

- **No business logic in widgets.** Widgets read providers and render. All fetching, mutation, validation, and mapping live in notifiers/repositories.
- **No direct repository/network calls from widgets** — go through a provider.
- Loading and error states are **always** surfaced via `AsyncValue` and rendered with `LoadingShimmer` / `ErrorView`. No unhandled error paths.
- **Skeleton loading is mandatory.** Every content `loading:` branch renders a **skeleton shimmer that mirrors the real content layout** (a `ProductGrid` loads into a grid of card skeletons, a list into row skeletons, a detail page into its block skeleton). A bare centered `CircularProgressIndicator` is **not** acceptable for content loading — use it only for inline/button spinners. Each screen ships a matching `LoadingShimmer` variant.
- Side-effect mutations (add to cart, login) live in notifier methods; widgets call `ref.read(xProvider.notifier).method()`.
- Reach for `.autoDispose` on providers that shouldn't outlive their last listener; use `ref.keepAlive()` deliberately when caching is needed.

---

## 8. Coding Standards

- **Null safety**: no `!` bang operator except where provably non-null with a comment; prefer pattern matching and `?.`/`??`.
- **Immutability**: models and state are **plain immutable classes** (`final` fields + `const` constructor); use `sealed`/`final` classes where they fit. Never mutate state in place — copy with a hand-written `copyWith`.
- **Typed errors**: a single `Failure` hierarchy (sealed class) — `NetworkFailure`, `ShopifyFailure`, `AuthFailure`, `UnknownFailure`. Repositories return `Result<T, Failure>` (or `Either`). **No silent catches** (`catch (_) {}` is forbidden); every catch maps to a `Failure` or rethrows.
- **Async**: always `await` futures or explicitly handle them; no unawaited fire-and-forget (lint: `unawaited_futures`, `discarded_futures`). Use `unawaited()` when intentional.
- **Comments**: doc comments (`///`) on public APIs and shared widgets. Inline comments only where logic is non-obvious — no narrating obvious code.
- **Const**: use `const` constructors wherever possible.

### Linting

`analysis_options.yaml` uses **`very_good_analysis`** (strict) — upgrade from the current `flutter_lints`. Treat warnings as errors in CI.

```yaml
include: package:very_good_analysis/analysis_options.yaml
analyzer:
  language:
    strict-casts: true
    strict-raw-types: true
linter:
  rules:
    public_member_api_docs: false        # enable on shared/ if desired
```

A change that adds analyzer warnings is not done.

---

## 9. Testing Expectations

- **Repositories & notifiers**: unit tests are required. Mock the `ApiClient` (e.g. `mocktail`) and assert DTO→entity mapping, `Failure` mapping, and notifier state transitions (`loading → data`, `loading → error`).
- **Shared widgets**: widget tests for each component in `shared/widgets/` covering variants and states (loading/disabled/error).
- **Shopify mocking**: never hit the real API in tests. Inject a fake/mock `ApiClient` returning canned JSON fixtures (store fixtures under `test/fixtures/`). Use `ProviderContainer` with overrides to supply mocks to providers.
- Aim for meaningful coverage on `data/` and `presentation/providers/`; UI screens get smoke tests.

```dart
test('Products notifier emits data on success', () async {
  final container = ProviderContainer(overrides: [
    productRepositoryProvider.overrideWithValue(FakeProductRepository()),
  ]);
  addTearDown(container.dispose);
  expect(await container.read(productsProvider.future), isA<List<Product>>());
});
```

---

## 10. Commands & Workflow

> Replace `<flavor>` with the tenant id (e.g. `acme`). Flavor + config plumbing must be added when scaffolding tenants.

```bash
# Install deps
flutter pub get

# Run a tenant flavor
flutter run --flavor <flavor> --dart-define-from-file=config/flavors/<flavor>.env

# No code generation in this repo — there is no build_runner step.

# Tests
flutter test
flutter test test/features/cart/                            # scoped

# Lint & format (must be clean before commit)
flutter analyze
dart format --set-exit-if-changed .

# Release builds
flutter build apk    --flavor <flavor> --dart-define-from-file=config/flavors/<flavor>.env
flutter build ipa    --flavor <flavor> --dart-define-from-file=config/flavors/<flavor>.env
```

### Definition of done for any change
1. `flutter analyze` clean (zero warnings under `very_good_analysis`).
2. `dart format` clean.
3. Tests added/updated and `flutter test` green.
4. No hardcoded colors/spacing/text styles, no business logic in widgets, no direct GraphQL outside repositories.

---

## Dependencies

No-codegen stack — no `build_runner`, `freezed`, `json_serializable`, or `riverpod_generator`. Current `pubspec.yaml`:

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  go_router: ^14.6.2
  dio: ^5.7.0            # Storefront GraphQL transport (ApiClient)
  flutter_dotenv: ^5.2.1 # tenant .env loading
  flutter_svg: ^2.3.0
  intl: ^0.19.0

dev_dependencies:
  very_good_analysis: ^6.0.0
  mocktail: ^1.0.4
```
