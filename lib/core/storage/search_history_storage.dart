import 'package:shared_preferences/shared_preferences.dart';

/// Persists the shopper's recent search terms across launches.
///
/// An interface so tests can inject a fake instead of touching disk.
abstract interface class SearchHistoryStorage {
  /// Recent terms, most-recent first. Empty when nothing is stored.
  List<String> readTerms();

  /// Replaces the stored terms with [terms].
  Future<void> writeTerms(List<String> terms);
}

/// [SearchHistoryStorage] backed by `SharedPreferences`.
class SharedPrefsSearchHistoryStorage implements SearchHistoryStorage {
  const SharedPrefsSearchHistoryStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'search_history_terms';

  @override
  List<String> readTerms() => _prefs.getStringList(_key) ?? const [];

  @override
  Future<void> writeTerms(List<String> terms) =>
      _prefs.setStringList(_key, terms);
}
