import 'package:flutter/foundation.dart';

/// Safe, non-throwing JSON field parsers.
///
/// Every parser tolerates `null`, wrong types, and coercible values; on a bad
/// value it returns the fallback and (in debug) logs a structured warning
/// instead of crashing the whole `fromJson`. Use these in every model.

/// Verbosity of [ _log ] parse warnings.
enum ParseLogLevel { silent, warn, verbose }

/// Active log level. Lower to [ParseLogLevel.silent] in noisy environments.
ParseLogLevel globalParseLogLevel = ParseLogLevel.warn;

void _log(
  String model,
  String field,
  dynamic rawValue,
  String expectedType,
  dynamic fallback,
) {
  if (globalParseLogLevel == ParseLogLevel.silent) return;
  if (!kDebugMode) return;
  final got = '${rawValue.runtimeType} -> ${_truncate(rawValue)}';
  debugPrint(
    '[ParseWarning] $model.$field expected=$expectedType '
    'got=$got fallback=$fallback',
  );
}

String _truncate(dynamic v, [int max = 80]) {
  final s = '$v';
  return s.length > max ? '${s.substring(0, max)}…' : s;
}

/// Safe [String] field — never throws, logs on bad value.
String parseString(
  Map<String, dynamic> json,
  String field, {
  String fallback = '',
  String model = 'Unknown',
}) {
  final raw = json[field];
  if (raw == null) return fallback;
  if (raw is String) return raw.trim().isEmpty ? fallback : raw.trim();
  final coerced = raw.toString().trim();
  if (globalParseLogLevel == ParseLogLevel.verbose) {
    _log(model, field, raw, 'String', coerced);
  }
  return coerced.isEmpty ? fallback : coerced;
}

/// Safe nullable [String] field.
String? parseStringOrNull(
  Map<String, dynamic> json,
  String field, {
  String model = 'Unknown',
}) {
  final raw = json[field];
  if (raw == null) return null;
  if (raw is String) return raw.trim().isEmpty ? null : raw.trim();
  final coerced = raw.toString().trim();
  return coerced.isEmpty ? null : coerced;
}

/// Safe [int] field.
int parseInt(
  Map<String, dynamic> json,
  String field, {
  int fallback = 0,
  String model = 'Unknown',
}) {
  final raw = json[field];
  if (raw == null) return fallback;
  if (raw is int) return raw;
  if (raw is double) return raw.toInt();
  if (raw is bool) return raw ? 1 : 0;
  if (raw is String) {
    final s = raw.trim();
    final parsed = int.tryParse(s) ?? double.tryParse(s)?.toInt();
    if (parsed != null) return parsed;
  }
  _log(model, field, raw, 'int', fallback);
  return fallback;
}

/// Safe nullable [int] field.
int? parseIntOrNull(
  Map<String, dynamic> json,
  String field, {
  String model = 'Unknown',
}) {
  final raw = json[field];
  if (raw == null) return null;
  if (raw is int) return raw;
  if (raw is double) return raw.toInt();
  if (raw is String) {
    return int.tryParse(raw.trim()) ?? double.tryParse(raw.trim())?.toInt();
  }
  _log(model, field, raw, 'int?', null);
  return null;
}

/// Safe [double] field.
double parseDouble(
  Map<String, dynamic> json,
  String field, {
  double fallback = 0,
  String model = 'Unknown',
}) {
  final raw = json[field];
  if (raw == null) return fallback;
  if (raw is double) return raw;
  if (raw is int) return raw.toDouble();
  if (raw is bool) return raw ? 1 : 0;
  if (raw is String) {
    final parsed = double.tryParse(raw.trim());
    if (parsed != null) return parsed;
  }
  _log(model, field, raw, 'double', fallback);
  return fallback;
}

/// Safe nullable [double] field.
double? parseDoubleOrNull(
  Map<String, dynamic> json,
  String field, {
  String model = 'Unknown',
}) {
  final raw = json[field];
  if (raw == null) return null;
  if (raw is double) return raw;
  if (raw is int) return raw.toDouble();
  if (raw is String) return double.tryParse(raw.trim());
  _log(model, field, raw, 'double?', null);
  return null;
}

/// Safe [bool] field.
bool parseBool(
  Map<String, dynamic> json,
  String field, {
  bool fallback = false,
  String model = 'Unknown',
}) {
  final raw = json[field];
  if (raw == null) return fallback;
  if (raw is bool) return raw;
  if (raw is int) return raw != 0;
  if (raw is String) {
    final lower = raw.trim().toLowerCase();
    if (lower == 'true' || lower == '1' || lower == 'yes') return true;
    if (lower == 'false' || lower == '0' || lower == 'no') return false;
  }
  _log(model, field, raw, 'bool', fallback);
  return fallback;
}

/// Safe nullable [bool] field.
bool? parseBoolOrNull(
  Map<String, dynamic> json,
  String field, {
  String model = 'Unknown',
}) {
  final raw = json[field];
  if (raw == null) return null;
  if (raw is bool) return raw;
  if (raw is int) return raw != 0;
  if (raw is String) {
    final lower = raw.trim().toLowerCase();
    if (lower == 'true' || lower == '1' || lower == 'yes') return true;
    if (lower == 'false' || lower == '0' || lower == 'no') return false;
  }
  _log(model, field, raw, 'bool?', null);
  return null;
}

/// Safe [num] field.
num parseNum(
  Map<String, dynamic> json,
  String field, {
  num fallback = 0,
  String model = 'Unknown',
}) {
  final raw = json[field];
  if (raw == null) return fallback;
  if (raw is num) return raw;
  if (raw is bool) return raw ? 1 : 0;
  if (raw is String) {
    final parsed = num.tryParse(raw.trim());
    if (parsed != null) return parsed;
  }
  _log(model, field, raw, 'num', fallback);
  return fallback;
}

/// Safe [DateTime] field — parses ISO string or millisecond timestamp.
DateTime parseDateTime(
  Map<String, dynamic> json,
  String field, {
  DateTime? fallback,
  String model = 'Unknown',
}) {
  final fb = fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
  final raw = json[field];
  if (raw == null) return fb;
  if (raw is DateTime) return raw;
  if (raw is String) {
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed != null) return parsed;
  }
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
  _log(model, field, raw, 'DateTime', fb);
  return fb;
}

/// Safe nullable [DateTime] field.
DateTime? parseDateTimeOrNull(
  Map<String, dynamic> json,
  String field, {
  String model = 'Unknown',
}) {
  final raw = json[field];
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  if (raw is String) return DateTime.tryParse(raw.trim());
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
  _log(model, field, raw, 'DateTime?', null);
  return null;
}

/// Safe `List<T>` field — drops items that can't be produced.
List<T> parseList<T>(
  Map<String, dynamic> json,
  String field, {
  List<T> fallback = const [],
  String model = 'Unknown',
  T Function(dynamic item)? fromItem,
}) {
  final raw = json[field];
  if (raw == null) return fallback;
  if (raw is! List) {
    _log(model, field, raw, 'List<$T>', fallback);
    return fallback;
  }
  final result = <T>[];
  for (var i = 0; i < raw.length; i++) {
    try {
      result.add(fromItem != null ? fromItem(raw[i]) : raw[i] as T);
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('[ParseWarning] $model.$field[$i] dropped: $e');
      }
    }
  }
  return result;
}

/// Safe nested `Map<String, dynamic>` field — for embedded objects.
Map<String, dynamic> parseMap(
  Map<String, dynamic> json,
  String field, {
  Map<String, dynamic> fallback = const {},
  String model = 'Unknown',
}) {
  final raw = json[field];
  if (raw == null) return fallback;
  if (raw is Map<String, dynamic>) return raw;
  _log(model, field, raw, 'Map<String, dynamic>', fallback);
  return fallback;
}
