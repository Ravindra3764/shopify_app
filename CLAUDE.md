# CLAUDE.md

Guidance for Claude (and developers) working in this repository. Read this before writing code. The rules here are **mandatory**, not suggestions — they exist so any session produces consistent, production-grade output without re-explanation.

---

## 1. Project Overview

- **App**: Multi-tenant, white-label e-commerce app built in Flutter. One codebase, reskinned per client (the "tenant") via configuration — never via per-client code forks.
- **Backend**: Shopify **Storefront API** (GraphQL). We do **not** use the Admin API from the app. Storefront access tokens are public-scope tokens and are safe to ship in the client, but they are still treated as per-tenant config (see §3).
- **State management**: **Riverpod** with code generation (`riverpod_generator` / `riverpod_annotation`). The standard async primitive is **`AsyncNotifier`** (via `@riverpod` annotated classes). See §2.
- **Targets**: iOS + Android. Code must follow Flutter/Dart industry best practices and pass analysis with zero warnings.
- **Dart/Flutter**: Dart SDK `^3.10.4`. Use modern language features (records, patterns, sealed classes, `switch` expressions).

> The repo currently contains only the Flutter starter (`lib/main.dart` counter app). The structure below is the **target architecture**. When you scaffold new code, follow it exactly.

---

## 2. Architecture & Folder Structure

### Approach: Feature-first, with layered separation inside each feature

We use **feature-first** (not layer-first) because a white-label e-commerce app grows by *feature* (wishlist, reviews, search), and features are toggled per tenant. Feature-first keeps everything for a feature co-located, makes feature flags trivial to reason about, and lets a whole feature be added/removed without touching unrelated folders.

Inside each feature we still separate **data / domain / presentation** so business logic stays out of widgets and the backend stays swappable.

```
lib/
├── main.dart                  # Thin: bootstrap → runApp(ProviderScope(...))
├── bootstrap.dart             # Loads AppConfig, sets up ProviderScope overrides, error zone
├── app.dart                   # Root MaterialApp.router, theme wiring
│
├── core/                      # Cross-cutting, feature-agnostic
│   ├── constants/             # App-wide constants (durations, keys, regex)
│   ├── error/                 # Failure types, exception → Failure mapping
│   ├── network/              # GraphQL transport, interceptors, connectivity
│   ├── routing/               # GoRouter config, route names, guards
│   ├── theme/                 # AppTheme, AppColors, AppSpacing, AppTextStyles (§4)
│   ├── utils/                 # Pure helpers, extensions, formatters
│   └── result/                # Result/Either type for typed error handling
│
├── config/                    # White-label configuration (§3)
│   ├── app_config.dart        # AppConfig model (freezed)
│   ├── feature_flags.dart     # FeatureFlags model
│   ├── config_repository.dart # Loads + parses config
│   └── flavors/               # Per-tenant config payloads (assets or .env)
│
├── shopify/                   # Storefront API layer (§6)
│   ├── client/                # ShopifyClient wrapper, GraphQL setup
│   ├── queries/               # One file per domain: products, collections, cart…
│   ├── mutations/             # cart_create, cart_lines_add, customer_login…
│   └── models/                # Storefront DTOs (freezed + json_serializable)
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
    ├── shopify_providers.dart  # shopifyClientProvider, repository providers
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
| Generated notifier class | `<Noun>Notifier` → exposes `<noun>Provider` | `class CartNotifier` → `cartProvider` |
| Repository interface / impl | `XRepository` / `XRepositoryImpl` | `CartRepository` / `CartRepositoryImpl` |
| Freezed model | noun, no suffix | `Product`, `CartLine` |
| GraphQL DTO (if distinct from entity) | `XDto` | `ProductDto` |
| Screens | `XScreen` | `CartScreen` |
| Generated files | `*.g.dart`, `*.freezed.dart` | committed, never hand-edited |

---

## 3. White-Label Configuration System

The same binary must reskin per tenant **without changing any feature code**. All tenant-specific values flow through a single `AppConfig`.

### Single source of config

```dart
// config/app_config.dart
@freezed
class AppConfig with _$AppConfig {
  const factory AppConfig({
    required String appName,
    required String fontFamily,

    // Shopify (per tenant)
    required String shopifyDomain,          // e.g. acme.myshopify.com
    required String storefrontAccessToken,  // public Storefront token
    required String storefrontApiVersion,   // e.g. 2025-01

    // Theming (hex strings parsed into Color in AppTheme)
    required String primaryColorHex,
    required String secondaryColorHex,
    required String accentColorHex,

    // Branding assets
    required String logoAsset,
    required List<OnboardingSlide> onboarding,

    // Feature toggles
    required FeatureFlags features,
  }) = _AppConfig;

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);
}

@freezed
class FeatureFlags with _$FeatureFlags {
  const factory FeatureFlags({
    @Default(true) bool wishlistEnabled,
    @Default(false) bool reviewsEnabled,
    @Default(true) bool searchEnabled,
    @Default(false) bool guestCheckoutEnabled,
  }) = _FeatureFlags;

  factory FeatureFlags.fromJson(Map<String, dynamic> json) =>
      _$FeatureFlagsFromJson(json);
}
```

### Loading at startup

Config is loaded **before `runApp`**, then injected via a Riverpod override so it is synchronously available everywhere (no `AsyncValue` ceremony for config reads).

```dart
// bootstrap.dart
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await ConfigRepository().load(); // reads flavor asset/.env
  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const App(),
    ),
  );
}

// providers/config_providers.dart
@riverpod
AppConfig appConfig(Ref ref) => throw UnimplementedError(); // overridden in bootstrap

@riverpod
FeatureFlags featureFlags(Ref ref) => ref.watch(appConfigProvider).features;
```

`ConfigRepository.load()` resolves the active tenant from a compile-time flavor (`--dart-define=FLAVOR=acme`) and reads the matching `config/flavors/<flavor>.json` asset (or a remote config override that falls back to the bundled asset).

### Multiple tenants via flavors

- Each tenant = a **Flutter flavor** (`acme`, `globex`, …) configured in Android `build.gradle.kts` product flavors and iOS schemes/configs.
- Tenant config selected at build time with `--dart-define-from-file=config/flavors/acme.env` (or `--dart-define=FLAVOR=acme`).
- Bundle ID / application ID, app name, and launcher icon differ per flavor; everything else differs only through `AppConfig`.
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
| `CartItemTile` | qty stepper, remove action |
| `PriceTag` | compare-at strikethrough, currency from Shopify money |
| `RatingStars` | read-only + interactive |
| `SectionHeader` | title + optional "See all" action |
| `EmptyStateView` | icon, message, optional CTA |
| `LoadingShimmer` | skeleton placeholders (list/grid/card) |
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
  const CustomButton.primary({ /* ... */ });
  const CustomButton.outline({ /* ... */ });
  // ...
}
```

---

## 6. Shopify Storefront API Integration

### Client wrapper

`ShopifyClient` wraps the GraphQL client, injects the Storefront token + API version from `AppConfig`, and is the only place HTTP/GraphQL details live.

```dart
// shopify/client/shopify_client.dart
class ShopifyClient {
  ShopifyClient({required AppConfig config, http.Client? httpClient}) // DI for tests
      : _endpoint = Uri.https(
          config.shopifyDomain,
          '/api/${config.storefrontApiVersion}/graphql.json',
        ),
        _token = config.storefrontAccessToken,
        _http = httpClient ?? http.Client();

  Future<Map<String, dynamic>> query(String document, {Map<String, dynamic>? variables}) {
    // POST with headers:
    //   'X-Shopify-Storefront-Access-Token': _token
    //   'Content-Type': 'application/json'
    // Throws ShopifyException → mapped to Failure in repository.
  }
}

// providers/shopify_providers.dart
@riverpod
ShopifyClient shopifyClient(Ref ref) =>
    ShopifyClient(config: ref.watch(appConfigProvider));
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

- DTOs in `shopify/models/` are **freezed + json_serializable** with `fromJson`/`toJson`. Never hand-write parsing.
- Map Shopify money correctly (`amount` + `currencyCode`); don't store prices as raw doubles without currency.

### Repository pattern (mandatory)

UI and notifiers **never** call `ShopifyClient` or GraphQL directly. They depend on a repository **interface** in `domain/`; the `data/` layer implements it against Shopify and maps DTO → entity → `Failure`.

```dart
// features/cart/domain/cart_repository.dart
abstract interface class CartRepository {
  Future<Result<Cart, Failure>> getCart(String cartId);
  Future<Result<Cart, Failure>> addLine(String cartId, String variantId, int qty);
}

// features/cart/data/cart_repository_impl.dart
class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl(this._client);
  final ShopifyClient _client;
  // calls _client.query/mutate, maps responses, catches ShopifyException → Failure
}
```

This keeps the backend swappable — Shopify could be replaced without touching presentation.

---

## 7. State Management Rules (Riverpod)

### Standard patterns

| Use case | Provider type |
|---|---|
| Async data from a repository (products, cart, orders) | `@riverpod` class extending **`AsyncNotifier`** / `FamilyAsyncNotifier` |
| Synchronous derived/config values | `@riverpod` function provider |
| Mutable local UI state (form, filters, selected tab) | `@riverpod` class extending **`Notifier`** |
| Plain dependency (client, repo) | `@riverpod` function provider |

Use **code generation** (`@riverpod`) everywhere. Do not hand-write `StateNotifierProvider`/`Provider` constructors. `StateNotifier` is legacy — **do not** introduce it in new code; use `Notifier`/`AsyncNotifier`.

```dart
// features/product_listing/presentation/providers/products_provider.dart
@riverpod
class Products extends _$Products {
  @override
  Future<List<Product>> build() async {
    final repo = ref.watch(productRepositoryProvider);
    final result = await repo.getProducts();
    return result.fold((products) => products, (failure) => throw failure);
  }

  Future<void> loadMore() async { /* ... */ }
}
// → exposes `productsProvider`
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
- Side-effect mutations (add to cart, login) live in notifier methods; widgets call `ref.read(xProvider.notifier).method()`.
- Dispose/auto-dispose is the default (codegen autoDispose). Use `ref.keepAlive()` deliberately when caching is needed.

---

## 8. Coding Standards

- **Null safety**: no `!` bang operator except where provably non-null with a comment; prefer pattern matching and `?.`/`??`.
- **Immutability**: models and state are **freezed**; use `sealed`/`final` classes. Never mutate state in place — copy with `copyWith`.
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
  errors:
    invalid_annotation_target: ignore   # freezed/json noise
linter:
  rules:
    public_member_api_docs: false        # enable on shared/ if desired
```

A change that adds analyzer warnings is not done.

---

## 9. Testing Expectations

- **Repositories & notifiers**: unit tests are required. Mock the `ShopifyClient` (e.g. `mocktail`) and assert DTO→entity mapping, `Failure` mapping, and notifier state transitions (`loading → data`, `loading → error`).
- **Shared widgets**: widget tests for each component in `shared/widgets/` covering variants and states (loading/disabled/error).
- **Shopify mocking**: never hit the real API in tests. Inject a fake/mock `ShopifyClient` returning canned JSON fixtures (store fixtures under `test/fixtures/`). Use `ProviderContainer` with overrides to supply mocks to providers.
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

# Code generation (freezed, json_serializable, riverpod_generator)
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch  --delete-conflicting-outputs   # during dev

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
3. `build_runner` regenerated if models/providers changed (generated files committed).
4. Tests added/updated and `flutter test` green.
5. No hardcoded colors/spacing/text styles, no business logic in widgets, no direct GraphQL outside repositories.

---

## Dependencies to add (target)

These are not yet in `pubspec.yaml` — add as the architecture is built out:

```yaml
dependencies:
  flutter_riverpod: ^2.x
  riverpod_annotation: ^2.x
  go_router: ^14.x
  freezed_annotation: ^2.x
  json_annotation: ^4.x
  http: ^1.x            # or graphql_flutter/ferry if a full GraphQL client is preferred
  intl: ^0.19.x

dev_dependencies:
  build_runner: ^2.x
  riverpod_generator: ^2.x
  freezed: ^2.x
  json_serializable: ^6.x
  very_good_analysis: ^6.x
  mocktail: ^1.x
```
