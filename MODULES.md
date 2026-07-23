# Module Progress

Living tracker for every feature module. Update the **Status** and **Progress**
columns as work lands. Legend: ✅ done · 🟡 partial · 🔲 not started.

_Last updated: 2026-07-23 (Reviews module — read-only — landed on `feature/reviews-module`)_

---

## Summary

| Module | Layers (data / provider / screen) | Status | Progress |
|---|---|---|---|
| Splash | — / — / screen | ✅ | 100% |
| Home | ✅ / ✅ / ✅ | ✅ | 100% |
| Product Listing | ✅ / ✅ / ✅ | ✅ | 100% |
| Product Detail | ✅ / ✅ / ✅ | ✅ | 100% |
| Product Detail Sheet | ✅ / ✅ / ✅ | ✅ | 100% (flag OFF) |
| Cart | ✅ / ✅ / ✅ | ✅ | 100% |
| Checkout | ✅ / ✅ / ✅ | ✅ | 100% |
| Search | ✅ / ✅ / ✅ | ✅ | 100% |
| Wishlist | ✅ storage / ✅ / ✅ | ✅ | 100% (local-only) |
| Auth | ✅ / ✅ / ✅ | ✅ | 100% |
| Orders | ✅ / ✅ / ✅ | ✅ | 100% |
| Profile | ✅ / ✅ / ✅ | ✅ | 100% |
| Reviews | ✅ / ✅ / ✅ | ✅ | 100% (read-only) |

---

## Complete modules

### ✅ Splash
Startup screen. Config load + first route.

### ✅ Home
Collections + featured product rows. Repo + AsyncNotifier + screen. Uses
`WishlistProductCard` for square cards.

### ✅ Product Listing
Collection grid, pagination (`loadMore`). Repo + provider + screen.

### ✅ Product Detail
Full detail page: gallery, options, quantity, tabs, related products, sticky
Add-to-Cart / Buy-Now bar. Repo + provider + screen.

### ✅ Product Detail Sheet
Blinkit-style peek-carousel card with morph-to-fullscreen + bottom-sheet
drag-to-dismiss. **Behind `PRODUCT_DETAIL_SHEET_ENABLED` — currently `false` in
active `.env`.** Flip flag to `true` to route to `ProductSheetScreen`.

### ✅ Cart
Cart create / lines add / update / remove. Repo + provider + screen + qty
stepper.

### ✅ Search
Product search with query + results. Repo + provider + screen.

---

## Partial modules

### ✅ Checkout — 100%
Cart → checkout URL, in-app webview, promo codes, address book flags wired.
Post-payment **order verification** now closed: `OrderVerifier` snapshots the
customer's newest order id before payment, then polls `customer.orders` after
the thank-you redirect until a new order appears (id comparison, clock-skew
proof). The real order name is stamped on the confirmation + shown on the
confirmed screen, behind a "Confirming your order…" overlay. Guests keep the
cart-snapshot confirmation. Tests: `OrderVerifier` polling + edge cases.

### ✅ Wishlist — 100% (local-only)
Persistence (`WishlistStorage` over `SharedPreferences`) + providers +
`WishlistProductCard` + heart + double-tap + hint + screen all done. Survives
restart. **No required pending work.**
Optional enhancement only: **server-side sync** tied to customer account for
cross-device wishlist — needs Auth + customer metafields (Storefront has no
native wishlist). Blocked on Auth; skip unless a tenant asks.

---

## Complete modules (auth)

### ✅ Auth — 100%
Shopify Storefront classic customer auth. Login / register (auto-login) /
logout / silent session restore on launch / forgot-password. Token in
`flutter_secure_storage` (Keychain/Keystore). Soft screen-level gate.
- Repo + `AuthNotifier` (AsyncNotifier) + 3 screens + routes.
- Checkout attaches `customerAccessToken` to `buyerIdentity`; gated checkout
  now has a working sign-in button.
- Tests: repo mapping, notifier transitions, login-screen widget (17 tests).

### ✅ Profile — 100%
Real account view: identity header, quick links (Orders/Wishlist/Addresses),
sign-out; sign-in prompt when logged out. **My orders** now routes to the
Orders module. **More** section live: every configured store policy
(auto-detected from Settings → Policies — privacy, terms, refund, shipping,
subscription), plus optional About us / Help & support (Online Store → Pages,
per-tenant `ABOUT_PAGE_HANDLE` / `HELP_PAGE_HANDLE`; tile hidden when unset).
Content fetched via `ContentRepository` → `ContentPageScreen` (HTML flattened
to plain text).

## Pending modules

### ✅ Orders — 100%
Signed-in order history via `customer.orders` (buyer token). Paginated list
(infinite scroll) + detail (lines, price breakdown, shipping address,
humanized fulfillment/financial status). Repo + `OrdersNotifier`
(AsyncNotifier, loadMore) + list/detail screens + routes; Profile "My orders"
link now routes here (gated to sign-in). Tests: repo mapping + notifier.
Detail renders from the loaded `Order` (no second fetch).

### ✅ Reviews — 100% (read-only)
Read-first reviews, Storefront-native. Individual reviews read from
`product_review` **metaobjects** (`metaobjects(type:"product_review")`), matched
to the product by its `product` reference field and sorted newest-first; the
store's aggregate `reviews.rating` / `reviews.rating_count` metafields still
feed the summary. Repo + `Result`/`Failure` + `ReviewsNotifier`
(`AutoDisposeFamilyAsyncNotifier`, keyed by product GID, `loadMore`). Product
Reviews tab shows a summary card (avg + 5→1 distribution bars) + a 3-review
preview + "See all reviews" → `ProductReviewsScreen` (infinite scroll, shimmer,
empty/error states). Behind `REVIEWS_ENABLED`; degrades gracefully (aggregate +
"No reviews yet") for stores without the metaobject. Tests: repo
mapping/filter/sort/failure, notifier transitions + `loadMore`, `ReviewTile`.
- **Submit deferred (pluggable seam):** the Storefront API is read-only, so
  `ReviewRepository.submitReview` returns a "not configured" `Failure` and
  `REVIEW_SUBMISSION_ENABLED` defaults `false`. Wire a write provider
  (Judge.me / Yotpo / app-proxy) to enable the submit form — no presentation
  changes needed.

---

## Recommended build order

1. ~~**Auth**~~ ✅ done — unblocked the rest.
2. ~~**Profile**~~ ✅ done — policies live, My-orders link wired.
3. ~~**Orders**~~ ✅ done — `customer.orders` list + detail.
4. ~~**Checkout verification**~~ ✅ done — polls `customer.orders` post-payment.
5. ~~**Reviews**~~ ✅ done — read-only via `product_review` metaobjects; submit
   is a pluggable seam pending a tenant's write-provider choice.
