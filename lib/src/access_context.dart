import 'package:flutter/foundation.dart';

import 'access_key.dart';
import 'access_value.dart';

const Object _unset = Object();

/// Access facts for the current user, session, or request.
///
/// This class is intentionally provider-agnostic. Apps can populate it from
/// Firebase Remote Config, LaunchDarkly, Supabase claims, local account state,
/// or any other feature flag and authorization source.
@immutable
class AccessContext {
  /// Creates an access context and defensively copies all collections.
  AccessContext({
    this.userId,
    Set<String> enabledFeatures = const <String>{},
    Map<String, Object?> featureValues = const <String, Object?>{},
    Set<String> roles = const <String>{},
    Set<String> permissions = const <String>{},
    Map<String, Object?> attributes = const <String, Object?>{},
  })  : enabledFeatures = Set<String>.unmodifiable(enabledFeatures),
        featureValues = freezeAccessValueMap(featureValues),
        roles = Set<String>.unmodifiable(roles),
        permissions = Set<String>.unmodifiable(permissions),
        attributes = freezeAccessValueMap(attributes);

  /// An empty context with no feature flags, roles, permissions, or attributes.
  const AccessContext.empty()
      : userId = null,
        enabledFeatures = const <String>{},
        featureValues = const <String, Object?>{},
        roles = const <String>{},
        permissions = const <String>{},
        attributes = const <String, Object?>{};

  /// Creates an access context from typed access keys.
  factory AccessContext.fromKeys({
    String? userId,
    Set<AccessFeature> enabledFeatures = const <AccessFeature>{},
    Map<AccessFeature, Object?> featureValues =
        const <AccessFeature, Object?>{},
    Set<AccessRole> roles = const <AccessRole>{},
    Set<AccessPermission> permissions = const <AccessPermission>{},
    Map<AccessAttribute, Object?> attributes =
        const <AccessAttribute, Object?>{},
  }) {
    return AccessContext(
      userId: userId,
      enabledFeatures: accessKeySet(enabledFeatures),
      featureValues: accessKeyMap(featureValues),
      roles: accessKeySet(roles),
      permissions: accessKeySet(permissions),
      attributes: accessKeyMap(attributes),
    );
  }

  /// Creates an access context from JSON-compatible data.
  factory AccessContext.fromJson(Map<String, Object?> json) {
    return AccessContext(
      userId: jsonOptionalString(json, 'userId'),
      enabledFeatures: jsonStringSet(
        json['enabledFeatures'],
        'enabledFeatures',
      ),
      featureValues: jsonAccessValueMap(json['featureValues'], 'featureValues'),
      roles: jsonStringSet(json['roles'], 'roles'),
      permissions: jsonStringSet(json['permissions'], 'permissions'),
      attributes: jsonAccessValueMap(json['attributes'], 'attributes'),
    );
  }

  /// Optional stable user identifier.
  final String? userId;

  /// Feature flags considered enabled for the current user.
  final Set<String> enabledFeatures;

  /// Feature flag values, useful for remote config values or A/B variants.
  ///
  /// Boolean `true` values are treated as enabled by [hasFeature]. Other values
  /// can be matched through [AccessPolicy.featureValues].
  final Map<String, Object?> featureValues;

  /// Roles assigned to the current user, such as `admin` or `billing_manager`.
  final Set<String> roles;

  /// Fine-grained permissions assigned to the current user.
  final Set<String> permissions;

  /// Attribute bag used for ABAC checks, such as `teamId`, `plan`, or `region`.
  final Map<String, Object?> attributes;

  /// Returns `true` when [feature] is enabled.
  bool hasFeature(String feature) {
    if (enabledFeatures.contains(feature)) {
      return true;
    }
    return featureValues[feature] == true;
  }

  /// Returns `true` when [feature] is enabled.
  bool hasFeatureKey(AccessFeature feature) => hasFeature(feature.accessKey);

  /// Returns the configured value for [feature].
  Object? featureValue(String feature) {
    if (featureValues.containsKey(feature)) {
      return featureValues[feature];
    }
    if (enabledFeatures.contains(feature)) {
      return true;
    }
    return null;
  }

  /// Returns the configured value for [feature].
  Object? featureValueKey(AccessFeature feature) {
    return featureValue(feature.accessKey);
  }

  /// Returns `true` when [role] is present.
  bool hasRole(String role) => roles.contains(role);

  /// Returns `true` when [role] is present.
  bool hasRoleKey(AccessRole role) => hasRole(role.accessKey);

  /// Returns `true` when [permission] is present.
  bool hasPermission(String permission) => permissions.contains(permission);

  /// Returns `true` when [permission] is present.
  bool hasPermissionKey(AccessPermission permission) {
    return hasPermission(permission.accessKey);
  }

  /// Returns the attribute value for [name].
  Object? attribute(String name) => attributes[name];

  /// Returns the attribute value for [attribute].
  Object? attributeKey(AccessAttribute attribute) {
    return this.attribute(attribute.accessKey);
  }

  /// Creates a copy with selected fields replaced.
  AccessContext copyWith({
    Object? userId = _unset,
    Set<String>? enabledFeatures,
    Map<String, Object?>? featureValues,
    Set<String>? roles,
    Set<String>? permissions,
    Map<String, Object?>? attributes,
  }) {
    return AccessContext(
      userId: identical(userId, _unset) ? this.userId : userId as String?,
      enabledFeatures: enabledFeatures ?? this.enabledFeatures,
      featureValues: featureValues ?? this.featureValues,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
      attributes: attributes ?? this.attributes,
    );
  }

  /// Combines this context with [other].
  ///
  /// Set-based facts are unioned. Map-based facts from [other] override this
  /// context when both contain the same key. The resulting [userId] comes from
  /// [other] when present, otherwise this context's [userId] is retained.
  AccessContext merge(AccessContext other) {
    return AccessContext(
      userId: other.userId ?? userId,
      enabledFeatures: <String>{...enabledFeatures, ...other.enabledFeatures},
      featureValues: <String, Object?>{
        ...featureValues,
        ...other.featureValues,
      },
      roles: <String>{...roles, ...other.roles},
      permissions: <String>{...permissions, ...other.permissions},
      attributes: <String, Object?>{...attributes, ...other.attributes},
    );
  }

  /// Combines [contexts] in order.
  ///
  /// Later contexts override earlier map values. Empty input returns
  /// [AccessContext.empty].
  static AccessContext combine(Iterable<AccessContext> contexts) {
    var combined = const AccessContext.empty();
    for (final context in contexts) {
      combined = combined.merge(context);
    }
    return combined;
  }

  /// Converts this context into JSON-compatible data.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'userId': userId,
      'enabledFeatures': _sortedStrings(enabledFeatures),
      'featureValues': _sortedMap(featureValues),
      'roles': _sortedStrings(roles),
      'permissions': _sortedStrings(permissions),
      'attributes': _sortedMap(attributes),
    };
  }

  @override
  bool operator ==(Object other) {
    return other is AccessContext &&
        other.userId == userId &&
        setEquals(other.enabledFeatures, enabledFeatures) &&
        _accessMapsEqual(other.featureValues, featureValues) &&
        setEquals(other.roles, roles) &&
        setEquals(other.permissions, permissions) &&
        _accessMapsEqual(other.attributes, attributes);
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      Object.hashAllUnordered(enabledFeatures),
      Object.hashAllUnordered(featureValues.entries.map(_hashEntry)),
      Object.hashAllUnordered(roles),
      Object.hashAllUnordered(permissions),
      Object.hashAllUnordered(attributes.entries.map(_hashEntry)),
    );
  }

  static Object _hashEntry(MapEntry<String, Object?> entry) {
    return Object.hash(entry.key, accessValueHash(entry.value));
  }

  static bool _accessMapsEqual(
    Map<String, Object?> first,
    Map<String, Object?> second,
  ) {
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

  static List<String> _sortedStrings(Set<String> values) {
    return values.toList()..sort();
  }

  static Map<String, Object?> _sortedMap(Map<String, Object?> values) {
    final entries = values.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return <String, Object?>{
      for (final entry in entries) entry.key: entry.value,
    };
  }
}
