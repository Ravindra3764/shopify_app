import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/error/shopify_exception.dart';
import 'package:shopify_app/core/network/api_client.dart';
import 'package:shopify_app/features/auth/data/auth_repository_impl.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient client;
  late AuthRepositoryImpl repo;

  final futureExpiry = DateTime.now()
      .add(const Duration(days: 30))
      .toIso8601String();

  setUp(() {
    client = MockApiClient();
    repo = AuthRepositoryImpl(client);
  });

  void stub(Map<String, dynamic> data) {
    when(
      () => client.query(any(), variables: any(named: 'variables')),
    ).thenAnswer((_) async => data);
  }

  group('login', () {
    test('maps a token payload to a CustomerAccessToken', () async {
      stub({
        'customerAccessTokenCreate': {
          'customerAccessToken': {
            'accessToken': 'tok_123',
            'expiresAt': futureExpiry,
          },
          'customerUserErrors': <dynamic>[],
        },
      });

      final result = await repo.login(email: 'a@b.com', password: 'secret');

      final token = result.fold((t) => t, (_) => null);
      expect(token, isNotNull);
      expect(token!.accessToken, 'tok_123');
    });

    test('maps customerUserErrors to an AuthFailure', () async {
      stub({
        'customerAccessTokenCreate': {
          'customerAccessToken': null,
          'customerUserErrors': [
            {'code': 'UNIDENTIFIED_CUSTOMER', 'message': 'Wrong credentials'},
          ],
        },
      });

      final result = await repo.login(email: 'a@b.com', password: 'x');

      final failure = result.fold((_) => null, (f) => f);
      expect(failure, isA<AuthFailure>());
      expect(failure!.message, 'Wrong credentials');
    });

    test('maps a null token with no errors to an AuthFailure', () async {
      stub({
        'customerAccessTokenCreate': {
          'customerAccessToken': null,
          'customerUserErrors': <dynamic>[],
        },
      });

      final result = await repo.login(email: 'a@b.com', password: 'x');
      expect(result.fold((_) => null, (f) => f), isA<AuthFailure>());
    });

    test('maps a ShopifyException to a Failure', () async {
      when(
        () => client.query(any(), variables: any(named: 'variables')),
      ).thenThrow(const ShopifyException('boom', statusCode: 500));

      final result = await repo.login(email: 'a@b.com', password: 'x');
      expect(result.isSuccess, isFalse);
      expect(result.fold((_) => null, (f) => f), isA<Failure>());
    });
  });

  group('register', () {
    test('creates then logs in, returning a token', () async {
      // customerCreate has no errors, then customerAccessTokenCreate succeeds.
      when(
        () => client.query(any(), variables: any(named: 'variables')),
      ).thenAnswer((invocation) async {
        final document = invocation.positionalArguments.first as String;
        if (document.contains('customerCreate')) {
          return {
            'customerCreate': {
              'customer': {'id': 'gid://shopify/Customer/1'},
              'customerUserErrors': <dynamic>[],
            },
          };
        }
        return {
          'customerAccessTokenCreate': {
            'customerAccessToken': {
              'accessToken': 'tok_new',
              'expiresAt': futureExpiry,
            },
            'customerUserErrors': <dynamic>[],
          },
        };
      });

      final result = await repo.register(
        email: 'new@b.com',
        password: 'secret',
        firstName: 'Jane',
      );

      expect(result.fold((t) => t.accessToken, (_) => null), 'tok_new');
    });

    test('maps a taken-email error to an AuthFailure, no login', () async {
      stub({
        'customerCreate': {
          'customer': null,
          'customerUserErrors': [
            {'code': 'TAKEN', 'message': 'Email has already been taken'},
          ],
        },
      });

      final result = await repo.register(email: 'taken@b.com', password: 'x');

      final failure = result.fold((_) => null, (f) => f);
      expect(failure, isA<AuthFailure>());
      expect(failure!.message, 'Email has already been taken');
    });

    test('maps CUSTOMER_DISABLED to EmailVerificationRequired', () async {
      stub({
        'customerCreate': {
          'customer': null,
          'customerUserErrors': [
            {
              'code': 'CUSTOMER_DISABLED',
              'message': 'Please verify your email.',
            },
          ],
        },
      });

      final result = await repo.register(email: 'new@b.com', password: 'x');

      final failure = result.fold((_) => null, (f) => f);
      expect(failure, isA<EmailVerificationRequired>());
      expect(failure!.message, 'Please verify your email.');
    });
  });

  group('fetchCustomer', () {
    test('maps a customer node to a Customer', () async {
      stub({
        'customer': {
          'id': 'gid://shopify/Customer/1',
          'email': 'a@b.com',
          'firstName': 'Ada',
          'lastName': 'Lovelace',
          'phone': null,
        },
      });

      final result = await repo.fetchCustomer('tok');
      final customer = result.fold((c) => c, (_) => null);
      expect(customer?.email, 'a@b.com');
      expect(customer?.displayName, 'Ada Lovelace');
    });

    test('maps a null customer (bad token) to an AuthFailure', () async {
      stub({'customer': null});
      final result = await repo.fetchCustomer('bad');
      expect(result.fold((_) => null, (f) => f), isA<AuthFailure>());
    });
  });

  group('recover', () {
    test('returns success when no errors', () async {
      stub({
        'customerRecover': {'customerUserErrors': <dynamic>[]},
      });
      final result = await repo.recover('a@b.com');
      expect(result.isSuccess, isTrue);
    });
  });
}
