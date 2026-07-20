import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/result/result.dart';
import 'package:shopify_app/core/storage/auth_storage.dart';
import 'package:shopify_app/features/auth/domain/auth_repository.dart';
import 'package:shopify_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:shopify_app/features/auth/presentation/providers/auth_state.dart';
import 'package:shopify_app/providers/storage_providers.dart';
import 'package:shopify_app/shopify/models/customer.dart';
import 'package:shopify_app/shopify/models/customer_access_token.dart';

const _customer = Customer(
  id: 'gid://shopify/Customer/1',
  email: 'a@b.com',
  firstName: 'Ada',
);

CustomerAccessToken _token([String value = 'tok']) => CustomerAccessToken(
  accessToken: value,
  expiresAt: DateTime.now().add(const Duration(days: 30)),
);

/// Configurable fake repository — each field overrides one method's result.
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.loginResult,
    this.renewResult,
    this.customerResult,
  });

  Result<CustomerAccessToken, Failure>? loginResult;
  Result<CustomerAccessToken, Failure>? renewResult;
  Result<Customer, Failure>? customerResult;
  bool logoutCalled = false;

  @override
  Future<Result<CustomerAccessToken, Failure>> login({
    required String email,
    required String password,
  }) async => loginResult ?? Success(_token());

  @override
  Future<Result<CustomerAccessToken, Failure>> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async => Success(_token());

  @override
  Future<Result<void, Failure>> logout(String token) async {
    logoutCalled = true;
    return const Success(null);
  }

  @override
  Future<Result<CustomerAccessToken, Failure>> renew(String token) async =>
      renewResult ?? Success(_token());

  @override
  Future<Result<void, Failure>> recover(String email) async =>
      const Success(null);

  @override
  Future<Result<Customer, Failure>> fetchCustomer(String token) async =>
      customerResult ?? const Success(_customer);
}

/// In-memory [AuthStorage].
class _FakeAuthStorage implements AuthStorage {
  _FakeAuthStorage({String? token, DateTime? expiry})
    : _token = token,
      _expiry = expiry;

  String? _token;
  DateTime? _expiry;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<DateTime?> readExpiry() async => _expiry;

  @override
  Future<void> write(String token, DateTime expiresAt) async {
    _token = token;
    _expiry = expiresAt;
  }

  @override
  Future<void> clear() async {
    _token = null;
    _expiry = null;
  }
}

ProviderContainer _container(
  _FakeAuthRepository repo,
  _FakeAuthStorage storage,
) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      authStorageProvider.overrideWithValue(storage),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('AuthNotifier', () {
    test('build with no stored token → Unauthenticated', () async {
      final container = _container(_FakeAuthRepository(), _FakeAuthStorage());
      final state = await container.read(authProvider.future);
      expect(state, isA<Unauthenticated>());
      expect(container.read(isAuthenticatedProvider), isFalse);
    });

    test('restores a session from a valid stored token', () async {
      final storage = _FakeAuthStorage(
        token: 'saved',
        expiry: DateTime.now().add(const Duration(days: 10)),
      );
      final container = _container(_FakeAuthRepository(), storage);

      final state = await container.read(authProvider.future);
      expect(state, isA<Authenticated>());
      expect(container.read(currentCustomerProvider)?.email, 'a@b.com');
    });

    test(
      'drops the session when the token is rejected and renew fails',
      () async {
        final storage = _FakeAuthStorage(
          token: 'saved',
          expiry: DateTime.now().add(const Duration(days: 10)),
        );
        final repo = _FakeAuthRepository(
          // Stored token rejected, and renew also fails → sign out.
          customerResult: const Failed(AuthFailure('bad token')),
          renewResult: const Failed(AuthFailure('expired')),
        );
        final container = _container(repo, storage);

        final state = await container.read(authProvider.future);
        expect(state, isA<Unauthenticated>());
      },
    );

    test('login success → Authenticated + token persisted', () async {
      final storage = _FakeAuthStorage();
      final container = _container(_FakeAuthRepository(), storage);
      await container.read(authProvider.future);

      final failure = await container
          .read(authProvider.notifier)
          .login(email: 'a@b.com', password: 'secret');

      expect(failure, isNull);
      expect(container.read(isAuthenticatedProvider), isTrue);
      expect(await storage.readToken(), 'tok');
    });

    test('login failure returns failure and stays Unauthenticated', () async {
      final repo = _FakeAuthRepository(
        loginResult: const Failed(AuthFailure('bad creds')),
      );
      final container = _container(repo, _FakeAuthStorage());
      await container.read(authProvider.future);

      final failure = await container
          .read(authProvider.notifier)
          .login(email: 'a@b.com', password: 'x');

      expect(failure, isA<AuthFailure>());
      expect(container.read(isAuthenticatedProvider), isFalse);
    });

    test('logout clears storage and returns to Unauthenticated', () async {
      final storage = _FakeAuthStorage(
        token: 'saved',
        expiry: DateTime.now().add(const Duration(days: 10)),
      );
      final repo = _FakeAuthRepository();
      final container = _container(repo, storage);
      await container.read(authProvider.future);
      expect(container.read(isAuthenticatedProvider), isTrue);

      await container.read(authProvider.notifier).logout();

      expect(repo.logoutCalled, isTrue);
      expect(container.read(isAuthenticatedProvider), isFalse);
      expect(await storage.readToken(), isNull);
    });
  });
}
