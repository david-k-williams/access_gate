/// A typed access-control key that resolves to the string stored in policies.
///
/// Implement this from enums when app code wants compile-time key names while
/// keeping provider-facing values as strings.
abstract interface class AccessKey {
  /// Stable string used in feature flag providers, claims, or policy payloads.
  String get accessKey;
}

/// Marker interface for feature flag keys.
abstract interface class AccessFeature implements AccessKey {}

/// Marker interface for role keys.
abstract interface class AccessRole implements AccessKey {}

/// Marker interface for permission keys.
abstract interface class AccessPermission implements AccessKey {}

/// Marker interface for attribute keys.
abstract interface class AccessAttribute implements AccessKey {}

/// Convenience access key for enums that can use their enum name as the key.
extension AccessEnumKey on Enum {
  /// The enum case name, useful when it already matches the provider key.
  String get accessKey => name;
}

/// Converts typed access keys into their provider-facing string keys.
Set<String> accessKeySet<T extends AccessKey>(Iterable<T> keys) {
  return Set<String>.unmodifiable(keys.map((key) => key.accessKey));
}

/// Converts typed access-key maps into provider-facing string-key maps.
Map<String, Object?> accessKeyMap<T extends AccessKey>(Map<T, Object?> values) {
  return Map<String, Object?>.unmodifiable(
    values.map((key, value) => MapEntry<String, Object?>(key.accessKey, value)),
  );
}
