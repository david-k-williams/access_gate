import 'package:flutter/foundation.dart';

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
  }) : enabledFeatures = Set<String>.unmodifiable(enabledFeatures),
       featureValues = Map<String, Object?>.unmodifiable(featureValues),
       roles = Set<String>.unmodifiable(roles),
       permissions = Set<String>.unmodifiable(permissions),
       attributes = Map<String, Object?>.unmodifiable(attributes);

  /// An empty context with no feature flags, roles, permissions, or attributes.
  const AccessContext.empty()
    : userId = null,
      enabledFeatures = const <String>{},
      featureValues = const <String, Object?>{},
      roles = const <String>{},
      permissions = const <String>{},
      attributes = const <String, Object?>{};

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

  /// Returns `true` when [role] is present.
  bool hasRole(String role) => roles.contains(role);

  /// Returns `true` when [permission] is present.
  bool hasPermission(String permission) => permissions.contains(permission);

  /// Returns the attribute value for [name].
  Object? attribute(String name) => attributes[name];

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

  @override
  bool operator ==(Object other) {
    return other is AccessContext &&
        other.userId == userId &&
        setEquals(other.enabledFeatures, enabledFeatures) &&
        mapEquals(other.featureValues, featureValues) &&
        setEquals(other.roles, roles) &&
        setEquals(other.permissions, permissions) &&
        mapEquals(other.attributes, attributes);
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      Object.hashAllUnordered(enabledFeatures),
      Object.hashAll(featureValues.entries.map(_hashEntry)),
      Object.hashAllUnordered(roles),
      Object.hashAllUnordered(permissions),
      Object.hashAll(attributes.entries.map(_hashEntry)),
    );
  }

  static Object _hashEntry(MapEntry<String, Object?> entry) {
    return Object.hash(entry.key, entry.value);
  }
}
