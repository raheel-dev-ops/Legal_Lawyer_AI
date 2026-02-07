class TtlCacheEntry<T> {
  final T value;
  final DateTime storedAt;

  const TtlCacheEntry(this.value, this.storedAt);
}

class TtlCache {
  final Duration defaultTtl;
  final Map<String, TtlCacheEntry<dynamic>> _items = <String, TtlCacheEntry<dynamic>>{};

  TtlCache({required this.defaultTtl});

  T? get<T>(String key, {Duration? ttl}) {
    final entry = _items[key];
    if (entry == null) return null;
    final effectiveTtl = ttl ?? defaultTtl;
    if (effectiveTtl != Duration.zero) {
      final age = DateTime.now().difference(entry.storedAt);
      if (age > effectiveTtl) {
        _items.remove(key);
        return null;
      }
    }
    return entry.value as T;
  }

  void set<T>(String key, T value) {
    _items[key] = TtlCacheEntry<T>(value, DateTime.now());
  }

  void invalidate(String key) {
    _items.remove(key);
  }

  void invalidatePrefix(String prefix) {
    final keys = _items.keys.where((k) => k.startsWith(prefix)).toList();
    for (final key in keys) {
      _items.remove(key);
    }
  }

  void clear() {
    _items.clear();
  }
}
