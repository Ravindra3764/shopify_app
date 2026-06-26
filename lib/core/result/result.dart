import 'package:shopify_app/core/error/failure.dart';

/// Typed success-or-failure wrapper returned by repositories.
///
/// Pattern-match with [fold]; never throws across the data boundary.
///
/// ```dart
/// final result = await repo.getHome();
/// return result.fold((data) => data, (failure) => throw failure);
/// ```
sealed class Result<S, F extends Failure> {
  const Result();

  /// Folds both branches into a single value.
  R fold<R>(R Function(S value) onSuccess, R Function(F failure) onFailure);

  /// Whether this is a [Success].
  bool get isSuccess => this is Success<S, F>;
}

/// Successful result carrying [value].
final class Success<S, F extends Failure> extends Result<S, F> {
  const Success(this.value);

  final S value;

  @override
  R fold<R>(R Function(S value) onSuccess, R Function(F failure) onFailure) =>
      onSuccess(value);
}

/// Failed result carrying [failure].
final class Failed<S, F extends Failure> extends Result<S, F> {
  const Failed(this.failure);

  final F failure;

  @override
  R fold<R>(R Function(S value) onSuccess, R Function(F failure) onFailure) =>
      onFailure(failure);
}
