import 'package:flutter/foundation.dart';

import 'access_context.dart';
import 'access_decision.dart';

/// Custom access check for app-specific ABAC logic.
typedef AccessPredicate = bool Function(AccessContext context);

/// A provider-agnostic access policy.
///
/// Policies can combine feature flags, role-based access control (RBAC),
/// permission checks, and attribute-based access control (ABAC). All populated
/// requirements must pass for access to be allowed.
@immutable
class AccessPolicy {
  /// Creates a policy from explicit requirements.
  const AccessPolicy({
    this.allFeatures = const <String>{},
    this.anyFeatures = const <String>{},
    this.featureValues = const <String, Object?>{},
    this.allRoles = const <String>{},
    this.anyRoles = const <String>{},
    this.allPermissions = const <String>{},
    this.anyPermissions = const <String>{},
    this.attributes = const <String, Object?>{},
    this.predicate,
    this.predicateReason = 'Custom access rule rejected access.',
  });

  /// Creates a policy that requires a single enabled feature.
  factory AccessPolicy.feature(String feature) {
    return AccessPolicy(allFeatures: <String>{feature});
  }

  /// Creates a policy that requires a single role.
  factory AccessPolicy.role(String role) {
    return AccessPolicy(allRoles: <String>{role});
  }

  /// Creates a policy that requires a single permission.
  factory AccessPolicy.permission(String permission) {
    return AccessPolicy(allPermissions: <String>{permission});
  }

  /// Features that must all be enabled.
  final Set<String> allFeatures;

  /// Features where at least one must be enabled.
  final Set<String> anyFeatures;

  /// Feature values that must exactly match, useful for A/B variants.
  final Map<String, Object?> featureValues;

  /// Roles that must all be present.
  final Set<String> allRoles;

  /// Roles where at least one must be present.
  final Set<String> anyRoles;

  /// Permissions that must all be present.
  final Set<String> allPermissions;

  /// Permissions where at least one must be present.
  final Set<String> anyPermissions;

  /// Attribute values that must exactly match.
  final Map<String, Object?> attributes;

  /// Optional app-specific predicate for ABAC checks.
  final AccessPredicate? predicate;

  /// Reason used when [predicate] returns `false`.
  final String predicateReason;

  /// Returns `true` when this policy has no requirements.
  bool get isEmpty {
    return allFeatures.isEmpty &&
        anyFeatures.isEmpty &&
        featureValues.isEmpty &&
        allRoles.isEmpty &&
        anyRoles.isEmpty &&
        allPermissions.isEmpty &&
        anyPermissions.isEmpty &&
        attributes.isEmpty &&
        predicate == null;
  }

  /// Evaluates this policy against [context].
  AccessDecision evaluate(AccessContext context) {
    if (isEmpty) {
      return AccessDecision.allow;
    }

    final reasons = <String>[];
    _requireAll(
      reasons: reasons,
      values: allFeatures,
      hasValue: context.hasFeature,
      missingReason: (feature) => 'Missing feature flag: $feature.',
    );
    _requireAny(
      reasons: reasons,
      values: anyFeatures,
      hasValue: context.hasFeature,
      missingReason: (features) =>
          'Requires at least one feature flag: ${features.join(', ')}.',
    );

    for (final requirement in featureValues.entries) {
      final actual = context.featureValue(requirement.key);
      if (actual != requirement.value) {
        reasons.add(
          'Feature ${requirement.key} must equal ${requirement.value}.',
        );
      }
    }

    _requireAll(
      reasons: reasons,
      values: allRoles,
      hasValue: context.hasRole,
      missingReason: (role) => 'Missing role: $role.',
    );
    _requireAny(
      reasons: reasons,
      values: anyRoles,
      hasValue: context.hasRole,
      missingReason: (roles) =>
          'Requires at least one role: ${roles.join(', ')}.',
    );

    _requireAll(
      reasons: reasons,
      values: allPermissions,
      hasValue: context.hasPermission,
      missingReason: (permission) => 'Missing permission: $permission.',
    );
    _requireAny(
      reasons: reasons,
      values: anyPermissions,
      hasValue: context.hasPermission,
      missingReason: (permissions) =>
          'Requires at least one permission: ${permissions.join(', ')}.',
    );

    for (final requirement in attributes.entries) {
      final actual = context.attribute(requirement.key);
      if (actual != requirement.value) {
        reasons.add(
          'Attribute ${requirement.key} must equal ${requirement.value}.',
        );
      }
    }

    final predicate = this.predicate;
    if (predicate != null && !predicate(context)) {
      reasons.add(predicateReason);
    }

    if (reasons.isEmpty) {
      return AccessDecision.allow;
    }
    return AccessDecision.deny(reasons);
  }

  static void _requireAll({
    required List<String> reasons,
    required Set<String> values,
    required bool Function(String value) hasValue,
    required String Function(String value) missingReason,
  }) {
    for (final value in values) {
      if (!hasValue(value)) {
        reasons.add(missingReason(value));
      }
    }
  }

  static void _requireAny({
    required List<String> reasons,
    required Set<String> values,
    required bool Function(String value) hasValue,
    required String Function(Set<String> values) missingReason,
  }) {
    if (values.isNotEmpty && !values.any(hasValue)) {
      reasons.add(missingReason(values));
    }
  }
}
