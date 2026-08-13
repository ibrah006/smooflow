import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class _RefEntry {
  final String value;
  int count;
  int lastUsedMillis;

  _RefEntry({required this.value, this.count = 1, int? lastUsedMillis})
    : lastUsedMillis = lastUsedMillis ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
    'v': value,
    'c': count,
    't': lastUsedMillis,
  };

  factory _RefEntry.fromJson(Map<String, dynamic> json) => _RefEntry(
    value: json['v'] as String,
    count: json['c'] as int? ?? 1,
    lastUsedMillis: json['t'] as int?,
  );
}

/// Stores and ranks previously-used print spec "ref" values so they can be
/// suggested back to the user as they type.
///
/// Backed by SharedPreferences rather than a SQL database: this is a small,
/// flat list of strings with no relational structure or complex querying
/// needs, so a key-value store is simpler, cheaper to hit on every
/// keystroke, and avoids adding sqflite just to persist a string list.
class RefHistoryStore {
  RefHistoryStore._();
  static final RefHistoryStore instance = RefHistoryStore._();

  static const _prefsKey = 'print_spec_ref_history_v1';
  static const _maxEntries = 200; // hard cap so prefs never grows unbounded
  static const _defaultLimit = 8;

  List<_RefEntry>? _cache;

  Future<List<_RefEntry>> _load() async {
    if (_cache != null) return _cache!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      _cache = [];
      return _cache!;
    }
    try {
      final list = jsonDecode(raw) as List;
      _cache =
          list
              .map((e) => _RefEntry.fromJson(e as Map<String, dynamic>))
              .toList();
    } catch (_) {
      _cache = [];
    }
    return _cache!;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = _cache ?? [];
    await prefs.setString(
      _prefsKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  /// Call whenever a ref value is committed (a print spec is created or a
  /// ref field is saved), whether shared or per-size.
  Future<void> recordRef(String value) async {
    final v = value.trim();
    if (v.isEmpty) return;

    final entries = await _load();
    final idx = entries.indexWhere(
      (e) => e.value.toLowerCase() == v.toLowerCase(),
    );

    if (idx >= 0) {
      entries[idx].count += 1;
      entries[idx].lastUsedMillis = DateTime.now().millisecondsSinceEpoch;
    } else {
      entries.add(_RefEntry(value: v));
    }

    entries.sort(_rank);
    if (entries.length > _maxEntries) {
      entries.removeRange(_maxEntries, entries.length);
    }
    await _persist();
  }

  int _rank(_RefEntry a, _RefEntry b) {
    // Blend frequency and recency so a ref used often recently floats up,
    // but a one-off from months ago doesn't outrank something used today.
    final scoreA = a.count * 1000000 + (a.lastUsedMillis ~/ 1000);
    final scoreB = b.count * 1000000 + (b.lastUsedMillis ~/ 1000);
    return scoreB.compareTo(scoreA);
  }

  /// Up to [limit] suggestions matching [query], ranked by recency/frequency.
  /// Empty query returns the most-used refs overall (good for "show recent
  /// refs on focus" before the user has typed anything).
  Future<List<String>> getSuggestions({
    String query = '',
    int limit = _defaultLimit,
  }) async {
    final entries = await _load();
    final q = query.trim().toLowerCase();

    Iterable<_RefEntry> matches = entries;
    if (q.isNotEmpty) {
      final starts = entries.where((e) => e.value.toLowerCase().startsWith(q));
      final contains = entries.where(
        (e) =>
            !e.value.toLowerCase().startsWith(q) &&
            e.value.toLowerCase().contains(q),
      );
      matches = [...starts, ...contains];
    }

    final sorted = matches.toList()..sort(_rank);
    return sorted.take(limit).map((e) => e.value).toList();
  }

  /// Optional: let the user clear a bad/typo'd suggestion.
  Future<void> removeRef(String value) async {
    final entries = await _load();
    entries.removeWhere(
      (e) => e.value.toLowerCase() == value.trim().toLowerCase(),
    );
    await _persist();
  }
}
