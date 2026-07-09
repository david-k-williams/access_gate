/// Returns an immutable copy of a JSON-compatible access value.
///
/// Lists, maps, and sets are copied recursively. Other values are retained.
Object? freezeAccessValue(Object? value) {
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(freezeAccessValue));
  }
  if (value is Map) {
    return Map<Object?, Object?>.unmodifiable(<Object?, Object?>{
      for (final entry in value.entries)
        freezeAccessValue(entry.key): freezeAccessValue(entry.value),
    });
  }
  if (value is Set) {
    return Set<Object?>.unmodifiable(value.map(freezeAccessValue));
  }
  return value;
}

/// Returns an immutable copy of a string-keyed access-value map.
Map<String, Object?> freezeAccessValueMap(Map<String, Object?> values) {
  return Map<String, Object?>.unmodifiable(<String, Object?>{
    for (final entry in values.entries)
      entry.key: freezeAccessValue(entry.value),
  });
}

/// Compares JSON-compatible access values structurally.
bool accessValueEquals(Object? first, Object? second) {
  if (identical(first, second)) {
    return true;
  }
  if (first is List && second is List) {
    if (first.length != second.length) {
      return false;
    }
    for (var index = 0; index < first.length; index += 1) {
      if (!accessValueEquals(first[index], second[index])) {
        return false;
      }
    }
    return true;
  }
  if (first is Map && second is Map) {
    if (first.length != second.length) {
      return false;
    }
    for (final entry in first.entries) {
      if (!second.containsKey(entry.key) ||
          !accessValueEquals(entry.value, second[entry.key])) {
        return false;
      }
    }
    return true;
  }
  if (first is Set && second is Set) {
    if (first.length != second.length) {
      return false;
    }
    final unmatched = second.toList();
    for (final value in first) {
      final index = unmatched.indexWhere(
        (candidate) => accessValueEquals(value, candidate),
      );
      if (index == -1) {
        return false;
      }
      unmatched.removeAt(index);
    }
    return true;
  }
  return first == second;
}

/// Produces a hash code consistent with [accessValueEquals].
int accessValueHash(Object? value) {
  if (value is List) {
    return Object.hashAll(value.map(accessValueHash));
  }
  if (value is Map) {
    return Object.hashAllUnordered(
      value.entries.map(
        (entry) => Object.hash(
          accessValueHash(entry.key),
          accessValueHash(entry.value),
        ),
      ),
    );
  }
  if (value is Set) {
    return Object.hashAllUnordered(value.map(accessValueHash));
  }
  return value.hashCode;
}

/// Reads an optional string from decoded JSON.
String? jsonOptionalString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null || value is String) {
    return value as String?;
  }
  throw FormatException('Expected "$key" to be a string or null.');
}

/// Reads a string set from decoded JSON.
Set<String> jsonStringSet(Object? value, String key) {
  if (value == null) {
    return const <String>{};
  }
  if (value is! Iterable || value is String) {
    throw FormatException('Expected "$key" to be a list of strings.');
  }
  final result = <String>{};
  for (final item in value) {
    if (item is! String) {
      throw FormatException('Expected "$key" to contain only strings.');
    }
    result.add(item);
  }
  return Set<String>.unmodifiable(result);
}

/// Reads a string-keyed access-value map from decoded JSON.
Map<String, Object?> jsonAccessValueMap(Object? value, String key) {
  if (value == null) {
    return const <String, Object?>{};
  }
  if (value is! Map) {
    throw FormatException('Expected "$key" to be an object.');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('Expected "$key" to use only string keys.');
    }
    result[entry.key as String] = freezeAccessValue(entry.value);
  }
  return Map<String, Object?>.unmodifiable(result);
}

/// Reads a JSON object.
Map<String, Object?> jsonObject(Object? value, String key) {
  if (value is! Map) {
    throw FormatException('Expected "$key" to be an object.');
  }
  return jsonAccessValueMap(value, key);
}
