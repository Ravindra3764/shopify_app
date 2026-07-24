# White-Label Configurability Roadmap

**Status:** Planning · **Model:** compile-time `.env` per tenant (rebuild per tenant) ·
**Scope confirmed:** deepen the config surface across **Theming**, **Home/Nav layout**, and
**Shopify commerce features**. Explicitly *not* doing runtime credential entry, remote/OTA
config, auto-branding from the Shopify `shop` query, or an onboarding/admin wizard.

---

## 1. Context

The app is already a clean white-label shell: one binary reskins per tenant from a single
bundled `.env` → immutable `AppConfig` → Riverpod override. 14 feature flags gate ~20
well-isolated call sites; the repository/notifier pattern keeps Shopify swappable.

**The gap — configurability is shallow.** Only `appName`, `fontFamily` (not even bundled —
the pubspec `fonts:` block is commented out and `inter.ttf` is missing), 3 brand colors,
and `logo` are themeable. Everything else — neutrals, semantic colors, type scale, radii,
home section layout/order/counts, bottom-nav tabs — is hardcoded in Dart. There is no dark
mode. On the Shopify side the storefront is fixed: no collections browse, no
filters/sorting, no metafield content, no markets/currency, no recommendations.

**Goal.** A tenant can restyle (incl. dark mode), re-lay-out home + nav, and enable richer
commerce features — all by editing `.env`, no feature-code forks. Every addition is
**additive with today's values as defaults**, so existing tenant `.env` files keep working.

---

## 2. Guiding principles (apply to every item)

- New config → add a `final` field to `AppConfig` (or a bool to `FeatureFlags`), parsed in
  `fromEnv` via the existing `required()` / `optional()` / `flag()` helpers
  (`lib/config/app_config.dart:26-37`, `lib/config/feature_flags.dart:23-32`). No codegen.
- `.env` is flat `key=value`. Prefer scalar/CSV keys; use a single JSON-string value only
  where structure is unavoidable (home sections), parsed with `dart:convert`.
- No hardcoded colors/spacing/text — route everything through `core/theme/`.
- Shopify reads go through repositories in `data/`, DTOs in `shopify/models/`, GraphQL docs
  as `const String` in `shopify/queries/`. Notifiers extend `AsyncNotifier`; UI uses
  `AsyncValue.when` with a matching `LoadingShimmer` variant.
- Flags only — never branch on tenant name. Document each new key in `.env` with a comment.
- Per CLAUDE.md §0: each phase on its own `feature/<kebab>` branch → PR into `main`;
  analyzer clean under `very_good_analysis`, `dart format` clean, tests green.

---

## 3. Workstream A — Theming depth

**Problem.** `AppColors` holds only `primary/secondary/accent` from config as mutable
`static late` globals (`lib/core/theme/app_colors.dart:11-15`); all neutrals + semantics are
hardcoded `const`. `AppTheme` has only `.light()` — no `darkTheme`/`themeMode` in
`app.dart:17`. Type scale (`app_text_styles.dart`) hardcodes sizes/weights. Fonts are named
but not bundled.

### A1 — Configurable semantic + neutral palette
- New optional hex keys (each defaults to today's constant, so nothing breaks):
  `BACKGROUND_COLOR`, `SURFACE_COLOR`, `ERROR_COLOR`, `SUCCESS_COLOR`, `WARNING_COLOR`,
  `DISCOUNT_COLOR`, `RATING_COLOR`, `BORDER_COLOR`, `TEXT_PRIMARY_COLOR`,
  `TEXT_SECONDARY_COLOR`.
- Add matching nullable-hex fields to `AppConfig` (via `optional()`), parsed in `fromEnv`.
- **Refactor `AppColors` off `static late` globals** into a resolved palette per brightness.
  Cleanest Material-3 fit: a `ThemeExtension<AppPalette>` carrying neutrals/semantics, added
  to both light and dark `ThemeData`; widgets read
  `Theme.of(context).extension<AppPalette>()!`. Keep `AppColors.fromHex` as the parser.
- **Files:** `lib/core/theme/app_colors.dart` (→ `AppPalette` extension + builders),
  `app_theme.dart`, `lib/bootstrap.dart:22` (drop imperative `AppColors.init`), plus a sweep
  of widgets referencing `AppColors.background` etc.

### A2 — Dark mode
- `.env`: `THEME_MODE=system|light|dark` (default `light` → identical to today); optional
  dark overrides `DARK_PRIMARY_COLOR`, `DARK_BACKGROUND_COLOR`, … (fall back to an
  auto-derived dark scheme when absent).
- Add `AppTheme.dark(config)` mirroring `.light()` with `Brightness.dark` seed + dark
  `AppPalette`. Wire `darkTheme:` + `themeMode:` in `lib/app.dart`.
- **Files:** `lib/core/theme/app_theme.dart`, `lib/app.dart`, `AppConfig`.

### A3 — Configurable typography
- `.env`: `HEADING_FONT_FAMILY` (default = `FONT_FAMILY`) and `FONT_SCALE` (double, default
  `1.0`).
- `AppTextStyles.textTheme` takes both families + scale; multiply hardcoded sizes by
  `FONT_SCALE`, use the heading family for display/headline/title.
- **Files:** `lib/core/theme/app_text_styles.dart`, `AppConfig`, `AppTheme`.

### A4 — Configurable shape / radii
- `.env`: `CORNER_RADIUS_SCALE` (double, default `1.0`) — or discrete `CARD_RADIUS` /
  `BUTTON_RADIUS`. Multiply the `AppDimensions` radii when building card/button/input shapes
  so a tenant can go sharp vs pill.
- **Files:** `lib/core/theme/app_spacing.dart` (radius resolver), `AppTheme`.

### A5 — Make fonts actually work (currently broken)
- **Primary:** add `google_fonts`; resolve `FONT_FAMILY` / `HEADING_FONT_FAMILY` at runtime
  via `GoogleFonts.getFont(name)` inside `AppTextStyles` — any Google font name in `.env`
  "just works", cached on device. (New dep → add to `pubspec.yaml` + CLAUDE.md deps list.)
- **Offline / custom-font path:** bundle per-tenant TTFs — uncomment/fix the pubspec
  `fonts:` block, drop real files under `assets/fonts/`, family name matching `.env`.
- **Files:** `lib/core/theme/app_text_styles.dart`, `pubspec.yaml`, `assets/fonts/`.

---

## 4. Workstream B — Data-driven home & nav

**Problem.** Home section **types + order** are hardcoded (`home_screen.dart:68-108`), fetch
**counts** hardcoded (`home_repository_impl.dart:15-17`), and bottom-nav tabs are 3 hardcoded
entries (`app_shell.dart:15-32`).

### B1 — Config-driven home layout
- `.env` `HOME_SECTIONS` = ordered CSV of tokens, e.g.
  `HOME_SECTIONS=search,banners,collectionRows`. Companion counts: `HOME_BANNER_COUNT`,
  `HOME_COLLECTION_COUNT`, `HOME_PRODUCTS_PER_COLLECTION` (defaults = today's 10/10/6). For
  advanced per-section config (pin specific collection handles, a hero grid), support an
  optional `HOME_SECTIONS_JSON` (JSON array string via `dart:convert`) that supersedes CSV.
- **Model:** `sealed class HomeSection` (`SearchBarSection`, `BannerCarouselSection`,
  `CollectionRowsSection`, `ProductGridSection`) in `lib/features/home/domain/`.
  `AppConfig.homeSections` parsed in `fromEnv`.
- `_HomeContent` iterates `config.homeSections` via a `switch` expression → widget, instead
  of the fixed column. Turn the hardcoded fetch counts into home-query variables.
- **Files:** `lib/features/home/presentation/screens/home_screen.dart`,
  `home/data/home_repository_impl.dart`, home query in `lib/shopify/queries/`,
  new `home/domain/home_section.dart`, `AppConfig`.

### B2 — Config-driven bottom navigation
- `.env` `NAV_TABS` = ordered CSV from a known set, e.g. `NAV_TABS=home,search,cart,profile`
  (default `home,cart,profile`). Tabs whose feature flag is off are dropped (e.g. `search`
  needs `SEARCH_ENABLED`, `wishlist` needs `WISHLIST_ENABLED`).
- Build the `StatefulShellRoute` branches + `NavigationBar` destinations from a
  `List<NavTab>` derived from config. Each token maps to an existing route/branch — no new
  screens for home/cart/profile/search; a `wishlist` tab reuses the wishlist screen.
- **Files:** `lib/core/routing/app_shell.dart`, `app_router.dart`, `AppConfig` / `NavTab`.

---

## 5. Workstream C — More Shopify features

Each net-new feature is behind a `FeatureFlags` toggle, with a repository + `AsyncNotifier` +
shimmer, DTOs in `shopify/models/`, GraphQL in `shopify/queries/`. Ordered by value/effort.

### C1 — Collections browse / categories · flag `COLLECTIONS_MENU_ENABLED`
New `collections` feature: a browse screen/drawer listing all storefront collections
(`collections(first:)`, image + title); tap → existing product-listing screen by handle. Can
surface as a `catalog` nav tab (B2) or a home section (B1).
- **Files:** new `lib/features/collections/{data,domain,presentation}`,
  `lib/shopify/queries/collections_queries.dart`, flag in `feature_flags.dart`.

### C2 — Product filtering + sorting · flag `PRODUCT_FILTERS_ENABLED`
Highest commerce value. Storefront supports faceted `filters` + `sortKey` on
`collection.products`. Add a filter/sort sheet to product-listing: sort (price ↑/↓, newest,
best-selling) and facets (availability, price range, product type, vendor, variant options)
driven by the `filters` the API returns.
- **Files:** `lib/features/product_listing/**` (screen + new
  `presentation/providers/product_filters_provider.dart` as a `Notifier` for selected facets,
  feeding the products `AsyncNotifier`), listing query gains `filters` + `sortKey` vars, flag.

### C3 — Product metafields content · flag `PRODUCT_METAFIELDS_ENABLED`
Render merchant content on product detail (size guide, materials, specs, care) from
`metafields(identifiers:)`. Which namespaces/keys show is tenant config:
`PRODUCT_METAFIELDS=custom.size_guide,custom.materials` (CSV of `namespace.key`).
- **Files:** `AppConfig` (parse CSV → identifiers), product query adds `metafields`,
  `product_detail_screen.dart` renders a config-driven section, flag.

### C4 — Product recommendations · flag `RECOMMENDATIONS_ENABLED`
"You may also like" on product detail via `productRecommendations(productId:)`. Reuses
`WishlistProductCard` in a horizontal row (per CLAUDE.md square-card rule).
- **Files:** new query, `product_detail` provider + row widget, flag.

### C5 — Markets / multi-currency + localization · flag `MARKETS_ENABLED` (largest)
Use the `@inContext(country:, language:)` directive so prices/currency + language follow a
selected market. Country/language switcher (persisted), default from existing
`DEFAULT_COUNTRY`; available markets from the `localization` query. App strings via `intl`
(already a dependency).
- **Files:** `ApiClient` (inject `@inContext` vars / `Accept-Language`), a `marketProvider`
  (`Notifier`, persisted via `shared_preferences`), queries updated to accept context,
  switcher UI in profile/home, flag.
- **Note:** touches nearly every query — schedule last.

---

## 6. Phasing

| Phase | Contents | Why here |
|---|---|---|
| 1 | A1–A4 (palette, dark mode, typography, radii) | Foundational, self-contained, instantly visible |
| 1b | A5 (fonts) | Depends on `google_fonts` dep decision |
| 2 | B1, B2 (home sections, nav tabs) | Layout config on top of theming |
| 3 | C1 → C2 → C3 → C4 (collections, filters/sort, metafields, recs) | Commerce value, isolated features |
| 4 | C5 (markets / localization) | Broadest surface — last |

Each phase = its own `feature/<kebab>` branch and PR into `main`.

---

## 7. New `.env` keys (summary)

```env
# Theming
THEME_MODE=light                 # system|light|dark
BACKGROUND_COLOR="#F7F5F0"
SURFACE_COLOR="#FFFFFF"
ERROR_COLOR="#B00020"
SUCCESS_COLOR="#2E7D32"
WARNING_COLOR="#ED6C02"
DISCOUNT_COLOR="#D32F2F"
RATING_COLOR="#FFB300"
BORDER_COLOR="#E0E0E0"
TEXT_PRIMARY_COLOR="#1A1A1A"
TEXT_SECONDARY_COLOR="#6B6B6B"
DARK_PRIMARY_COLOR=              # optional dark overrides (blank = auto-derive)
DARK_BACKGROUND_COLOR=
HEADING_FONT_FAMILY=             # blank = same as FONT_FAMILY
FONT_SCALE=1.0
CORNER_RADIUS_SCALE=1.0

# Layout
HOME_SECTIONS=search,banners,collectionRows
HOME_BANNER_COUNT=10
HOME_COLLECTION_COUNT=10
HOME_PRODUCTS_PER_COLLECTION=6
NAV_TABS=home,cart,profile

# Shopify features
COLLECTIONS_MENU_ENABLED=false
PRODUCT_FILTERS_ENABLED=false
PRODUCT_METAFIELDS_ENABLED=false
PRODUCT_METAFIELDS=custom.size_guide,custom.materials
RECOMMENDATIONS_ENABLED=false
MARKETS_ENABLED=false
```

*(Every key optional; blank/absent = current behavior.)*

---

## 8. Critical files (touch points)

- **Config core:** `lib/config/app_config.dart`, `feature_flags.dart`, `config_repository.dart`, root `.env`.
- **Theme:** `lib/core/theme/{app_colors,app_theme,app_text_styles,app_spacing}.dart`; `lib/app.dart`; `lib/bootstrap.dart`.
- **Home/nav:** `lib/features/home/presentation/screens/home_screen.dart`, `home/data/home_repository_impl.dart`, `lib/core/routing/{app_shell,app_router}.dart`.
- **New features:** `lib/features/collections/`, `lib/features/product_listing/**`, `lib/features/product_detail/**`, `lib/shopify/queries/*`, `lib/shopify/models/*`.
- **Deps:** `pubspec.yaml` (add `google_fonts` for A5).

---

## 9. Verification

- **Per phase:** `flutter analyze` (zero warnings) + `dart format --set-exit-if-changed .` + `flutter test`.
- **Config parsing:** unit-test `AppConfig.fromEnv` / `FeatureFlags.fromEnv` with new keys present, absent (defaults hold), malformed (fail-fast `StateError`).
- **Theming:** toggle `THEME_MODE` and override a semantic color / `FONT_SCALE` in `.env`, relaunch — whole app reskins with no code change; verify light + dark.
- **Layout:** reorder `HOME_SECTIONS`, change `NAV_TABS`, relaunch — sections + tabs follow config; disabled-flag tabs drop out.
- **Shopify features:** mock `ApiClient` with fixtures under `test/fixtures/` for each new repo (collections, filters, metafields, recommendations); assert DTO→entity + `Failure` mapping and notifier `loading→data/error`. Manual smoke against the live test store for each feature.
- **Regression:** an untouched existing tenant `.env` (no new keys) must build + behave exactly as today.

---

## 10. Out of scope (by decision)

Runtime in-app credential entry · remote/OTA config backend · auto-branding from the Shopify
`shop` query · onboarding/admin/preview surface. The model stays: **edit `.env`, rebuild per
tenant.**
