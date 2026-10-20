import 'package:shared_preferences/shared_preferences.dart';

/// Persists the newest changelog version the user has seen, powering
/// "What's New" detection.
abstract class SeenVersionStore {
  /// Returns the last version string marked as seen, or null.
  Future<String?> lastSeenVersion();

  /// Records [version] as seen.
  Future<void> markSeen(String version);
}

/// [SharedPreferences]-backed store used by default.
class SharedPrefsSeenStore implements SeenVersionStore {
  /// Creates a store persisting under [storageKey].
  const SharedPrefsSeenStore({this.storageKey = 'changelog_widget.seen'});

  /// SharedPreferences key.
  final String storageKey;

  @override
  Future<String?> lastSeenVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(storageKey);
  }

  @override
  Future<void> markSeen(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, version);
  }
}

/// In-memory store for tests and previews.
class InMemorySeenStore implements SeenVersionStore {
  /// Creates an empty store.
  InMemorySeenStore();

  String? _seen;

  @override
  Future<String?> lastSeenVersion() async => _seen;

  @override
  Future<void> markSeen(String version) async => _seen = version;
}
