# Module Progress

Living tracker for every feature module. Update the **Status** and **Progress**
columns as work lands. Legend: ✅ done · 🟡 partial · 🔲 not started.

_Last updated: 2026-07-20 (Auth module landed on `feature/auth-module`)_

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
| Checkout | ✅ / ✅ / ✅ | 🟡 | 90% |
| Search | ✅ / ✅ / ✅ | ✅ | 100% |
| Wishlist | ✅ storage / ✅ / ✅ | ✅ | 100% (local-only) |
| Auth | ✅ / ✅ / ✅ | ✅ | 100% |
| Orders | 🔲 / 🔲 / 🔲 | 🔲 | 0% |
| Profile | — / ✅ / ✅ | ✅ | 90% |
| Reviews | 🔲 / 🔲 / 🔲 | 🔲 | 0% |

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

### 🟡 Checkout — 90%
Cart → checkout URL, in-app webview, promo codes, address book flags wired.
**Pending:** order verification after payment — deferred until customer auth
lands (need `customerAccessToken` + poll `customer.orders`).

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

### ✅ Profile — 90%
Real account view: identity header, quick links (Orders/Wishlist/Addresses),
sign-out; sign-in prompt when logged out. **Pending:** Orders + Addresses links
are placeholders (snackbar) until those modules exist.

## Pending modules

### 🔲 Orders — 0% (NEXT — now unblocked by Auth)
Missing. Uses the auth token.
- Query `customer.orders` list + order detail.
- Repo + provider + list/detail screens; wire the Profile "My orders" link.

### 🔲 Reviews — 0%
Missing. `REVIEWS_ENABLED=false`. Product tabs show placeholder only.
- Shopify Storefront has no native reviews → metafields or 3rd-party provider.
- List + submit, `RatingStars` interactive.

---

## Recommended build order

1. ~~**Auth**~~ ✅ done — unblocked the rest.
2. ~~**Profile**~~ ✅ done (links pending their modules).
3. **Orders** — needs Auth token (next).
4. **Checkout verification** — close the 10% gap now that the Auth token exists.
5. **Reviews** — needs data-source decision (metafields vs 3rd-party).
