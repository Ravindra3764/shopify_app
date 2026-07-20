import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/core/storage/auth_storage.dart';
import 'package:shopify_app/features/auth/data/auth_repository_impl.dart';
import 'package:shopify_app/features/auth/domain/auth_repository.dart';
import 'package:shopify_app/features/auth/presentation/providers/auth_state.dart';
import 'package:shopify_app/providers/shopify_providers.dart';
import 'package:shopify_app/providers/storage_providers.dart';
import 'package:shopify_app/shopify/models/customer.dart';
import 'package:shopify_app/shopify/models/customer_access_token.dart';

/// Auth repository, wired to the Storefront `ApiClient`.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(apiClientProvider)),
);

/// The customer session. `loading` while restoring on launch; `data` holds an
/// [Authenticated] or [Unauthenticated] state thereafter.
final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Whether a customer is currently signed in.
final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(authProvider).valueOrNull is Authenticated,
);

/// The signed-in customer, or `null` when browsing as a guest.
final currentCustomerProvider = Provider<Customer?>((ref) {
  final state = ref.watch(authProvider).valueOrNull;
  return state is Authenticated ? state.customer : null;
});

/// The active customer access token, or `null` when signed out. Consumed by
/// checkout to attach the buyer to their account.
final authTokenProvider = Provider<String?>((ref) {
  final state = ref.watch(authProvider).valueOrNull;
  return state is Authenticated ? state.token : null;
});

/// Holds the customer session and drives sign-in / sign-up / sign-out.
///
/// On launch [build] restores a persisted session by renewing the stored token
/// and re-fetching the customer; a failed renew drops the session silently.
/// [login]/[register]/[recover] return a [Failure] (or `null` on success) so
/// the calling screen can show inline errors without corrupting session state —
/// the notifier stays on a valid [AuthState] throughout.
class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    ref.keepAlive();
    return _restore();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  AuthStorage get _storage => ref.read(authStorageProvider);

  /// Restores a saved session, or returns [Unauthenticated] when there's none
  /// (or the stored token is expired / no longer accepted by Shopify).
  ///
  /// Optimised for the common case: the stored token is used directly (one
  /// request) and only renewed if Shopify actually rejects it — avoiding a
  /// renew round-trip on every launch. Never throws: if secure storage is
  /// unavailable (e.g. the plugin isn't registered on a fresh build), the
  /// shopper is treated as signed out so the profile still renders.
  Future<AuthState> _restore() async {
    try {
      final token = await _storage.readToken();
      final expiry = await _storage.readExpiry();
      if (token == null || expiry == null || !expiry.isAfter(DateTime.now())) {
        await _safeClear();
        return const Unauthenticated();
      }

      // Use the stored token as-is first.
      final customer = await _repo.fetchCustomer(token);
      if (customer case Success(value: final c)) {
        return Authenticated(customer: c, token: token);
      }

      // Rejected — try a single renew before giving up.
      final renewed = await _repo.renew(token);
      if (renewed case Success(:final value)) {
        final renewedCustomer = await _repo.fetchCustomer(value.accessToken);
        if (renewedCustomer case Success(value: final c)) {
          await _safeWrite(value.accessToken, value.expiresAt);
          return Authenticated(customer: c, token: value.accessToken);
        }
      }
      await _safeClear();
      return const Unauthenticated();
    } on Object catch (e) {
      if (kDebugMode) debugPrint('[Auth] session restore failed: $e');
      return const Unauthenticated();
    }
  }

  /// Signs in with email + password. Returns `null` on success, else the
  /// [Failure] to display; session state is untouched on failure.
  Future<Failure?> login({required String email, required String password}) =>
      _authenticate(() => _repo.login(email: email, password: password));

  /// Registers then signs the new customer in. Returns `null` on success.
  Future<Failure?> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) => _authenticate(
    () => _repo.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    ),
  );

  /// Sends a password-reset email. Returns `null` on success, else the failure.
  Future<Failure?> recover(String email) async {
    final result = await _repo.recover(email);
    return result.fold((_) => null, (failure) => failure);
  }

  /// Signs out: invalidates the token server-side (best-effort), clears secure
  /// storage, and drops to [Unauthenticated].
  Future<void> logout() async {
    final token = switch (state.valueOrNull) {
      Authenticated(:final token) => token,
      _ => null,
    };
    state = const AsyncLoading<AuthState>().copyWithPrevious(state);
    if (token != null) await _repo.logout(token);
    await _safeClear();
    state = const AsyncData(Unauthenticated());
  }

  /// Runs a token-producing op, then loads the customer and persists the
  /// session. Restores [Unauthenticated] and returns the failure on any step.
  Future<Failure?> _authenticate(
    Future<Result<CustomerAccessToken, Failure>> Function() op,
  ) async {
    state = const AsyncLoading<AuthState>().copyWithPrevious(state);
    final tokenResult = await op();
    switch (tokenResult) {
      case Failed(:final failure):
        state = const AsyncData(Unauthenticated());
        return failure;
      case Success(:final value):
        final customerResult = await _repo.fetchCustomer(value.accessToken);
        switch (customerResult) {
          case Failed(:final failure):
            state = const AsyncData(Unauthenticated());
            return failure;
          case Success(value: final customer):
            // Persist for next launch. A storage failure (e.g. the secure-
            // storage plugin isn't registered on this build) must not fail the
            // sign-in — the session still works in memory this run.
            await _safeWrite(value.accessToken, value.expiresAt);
            state = AsyncData(
              Authenticated(customer: customer, token: value.accessToken),
            );
            return null;
        }
    }
  }

  /// Writes the session to secure storage, swallowing (and logging) any
  /// platform/plugin error so it can't crash the auth flow.
  Future<void> _safeWrite(String token, DateTime expiresAt) async {
    try {
      await _storage.write(token, expiresAt);
    } on Object catch (e) {
      if (kDebugMode) debugPrint('[Auth] token persist failed: $e');
    }
  }

  /// Clears secure storage, swallowing (and logging) any platform/plugin error.
  Future<void> _safeClear() async {
    try {
      await _storage.clear();
    } on Object catch (e) {
      if (kDebugMode) debugPrint('[Auth] token clear failed: $e');
    }
  }
}
