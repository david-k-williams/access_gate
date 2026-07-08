import 'package:flutter/foundation.dart';

import 'access_context.dart';
import 'access_decision.dart';
import 'access_key.dart';

/// Custom access check for app-specific ABAC logic.
typedef AccessPredicate = bool Function(AccessContext context);

enum _AccessPolicyMode { leaf, allOf, anyOf, not }

/// A provider-agnostic access policy.
///
/// Policies can combine feature flags, role-based access control (RBAC),
/// permission checks, and attribute-based access control (ABAC). All populated
/// requirements must pass for access to be allowed. Use [AccessPolicy.allOf],
/// [AccessPolicy.anyOf], and [AccessPolicy.not] to compose policies into larger
/// access rules.
@immutable
class AccessPolicy {
  const AccessPolicy._({
    required this.allFeatures,
    required this.anyFeatures,
    required this.featureValues,
    required this.allRoles,
    required this.anyRoles,
    required this.allPermissions,
    required this.anyPermissions,
    required this.attributes,
    required this.predicate,
    required this.predicateReason,
    required this._mode,
    required this._policies,
    required this._notReason,
  });

  /// Creates a policy from explicit requirements.
  factory AccessPolicy({
    Set<String> allFeatures = const <String>{},
    Set<String> anyFeatures = const <String>{},
    Map<String, Object?> featureValues = const <String, Object?>{},
    Set<String> allRoles = const <String>{},
    Set<String> anyRoles = const <String>{},
    Set<String> allPermissions = const <String>{},
    Set<String> anyPermissions = const <String>{},
    Map<String, Object?> attributes = const <String, Object?>{},
    AccessPredicate? predicate,
    String predicateReason = 'Custom access rule rejected access.',
  }) {
    return AccessPolicy._(
      allFeatures: Set<String>.unmodifiable(allFeatures),
      anyFeatures: Set<String>.unmodifiable(anyFeatures),
      featureValues: Map<String, Object?>.unmodifiable(featureValues),
      allRoles: Set<String>.unmodifiable(allRoles),
      anyRoles: Set<String>.unmodifiable(anyRoles),
      allPermissions: Set<String>.unmodifiable(allPermissions),
      anyPermissions: Set<String>.unmodifiable(anyPermissions),
      attributes: Map<String, Object?>.unmodifiable(attributes),
      predicate: predicate,
      predicateReason: predicateReason,
      mode: _AccessPolicyMode.leaf,
      policies: const <AccessPolicy>[],
      notReason: _defaultNotReason,
    );
  }

  static const String _defaultNotReason = 'Access matched a denied policy.';

  /// A reusable policy with no requirements.
  static const AccessPolicy empty = AccessPolicy._(
    allFeatures: <String>{},
    anyFeatures: <String>{},
    featureValues: <String, Object?>{},
    allRoles: <String>{},
    anyRoles: <String>{},
    allPermissions: <String>{},
    anyPermissions: <String>{},
    attributes: <String, Object?>{},
    predicate: null,
    predicateReason: 'Custom access rule rejected access.',
    mode: _AccessPolicyMode.leaf,
    policies: <AccessPolicy>[],
    notReason: _defaultNotReason,
  );

  /// Creates a policy that requires every child policy to allow access.
  factory AccessPolicy.allOf(Iterable<AccessPolicy> policies) {
    return AccessPolicy._composed(
      mode: _AccessPolicyMode.allOf,
      policies: policies,
    );
  }

  /// Creates a policy that requires at least one child policy to allow access.
  factory AccessPolicy.anyOf(Iterable<AccessPolicy> policies) {
    return AccessPolicy._composed(
      mode: _AccessPolicyMode.anyOf,
      policies: policies,
    );
  }

  /// Creates a policy that allows access only when [policy] denies access.
  factory AccessPolicy.not(
    AccessPolicy policy, {
    String reason = _defaultNotReason,
  }) {
    return AccessPolicy._composed(
      mode: _AccessPolicyMode.not,
      policies: <AccessPolicy>[policy],
      notReason: reason,
    );
  }

  factory AccessPolicy._composed({
    required _AccessPolicyMode mode,
    required Iterable<AccessPolicy> policies,
    String notReason = _defaultNotReason,
  }) {
    return AccessPolicy._(
      allFeatures: const <String>{},
      anyFeatures: const <String>{},
      featureValues: const <String, Object?>{},
      allRoles: const <String>{},
      anyRoles: const <String>{},
      allPermissions: const <String>{},
      anyPermissions: const <String>{},
      attributes: const <String, Object?>{},
      predicate: null,
      predicateReason: 'Custom access rule rejected access.',
      mode: mode,
      policies: List<AccessPolicy>.unmodifiable(policies),
      notReason: notReason,
    );
  }

  /// Creates a policy from typed access keys.
  factory AccessPolicy.fromKeys({
    Set<AccessFeature> allFeatures = const <AccessFeature>{},
    Set<AccessFeature> anyFeatures = const <AccessFeature>{},
    Map<AccessFeature, Object?> featureValues =
        const <AccessFeature, Object?>{},
    Set<AccessRole> allRoles = const <AccessRole>{},
    Set<AccessRole> anyRoles = const <AccessRole>{},
    Set<AccessPermission> allPermissions = const <AccessPermission>{},
    Set<AccessPermission> anyPermissions = const <AccessPermission>{},
    Map<AccessAttribute, Object?> attributes =
        const <AccessAttribute, Object?>{},
    AccessPredicate? predicate,
    String predicateReason = 'Custom access rule rejected access.',
  }) {
    return AccessPolicy(
      allFeatures: accessKeySet(allFeatures),
      anyFeatures: accessKeySet(anyFeatures),
      featureValues: accessKeyMap(featureValues),
      allRoles: accessKeySet(allRoles),
      anyRoles: accessKeySet(anyRoles),
      allPermissions: accessKeySet(allPermissions),
      anyPermissions: accessKeySet(anyPermissions),
      attributes: accessKeyMap(attributes),
      predicate: predicate,
      predicateReason: predicateReason,
    );
  }

  /// Creates a policy that requires a single enabled feature.
  factory AccessPolicy.feature(String feature) {
    return AccessPolicy(allFeatures: <String>{feature});
  }

  /// Creates a policy that requires a single enabled typed feature key.
  factory AccessPolicy.featureKey(AccessFeature feature) {
    return AccessPolicy.feature(feature.accessKey);
  }

  /// Creates a policy that requires a single role.
  factory AccessPolicy.role(String role) {
    return AccessPolicy(allRoles: <String>{role});
  }

  /// Creates a policy that requires a single typed role key.
  factory AccessPolicy.roleKey(AccessRole role) {
    return AccessPolicy.role(role.accessKey);
  }

  /// Creates a policy that requires a single permission.
  factory AccessPolicy.permission(String permission) {
    return AccessPolicy(allPermissions: <String>{permission});
  }

  /// Creates a policy that requires a single typed permission key.
  factory AccessPolicy.permissionKey(AccessPermission permission) {
    return AccessPolicy.permission(permission.accessKey);
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

  final _AccessPolicyMode _mode;
  final List<AccessPolicy> _policies;
  final String _notReason;

  /// Returns `true` when this policy has no requirements.
  bool get isEmpty {
    if (_mode == _AccessPolicyMode.allOf) {
      return _policies.every((policy) => policy.isEmpty);
    }
    if (_mode != _AccessPolicyMode.leaf) {
      return false;
    }

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
    return switch (_mode) {
      _AccessPolicyMode.leaf => _evaluateLeaf(context),
      _AccessPolicyMode.allOf => _evaluateAllOf(context),
      _AccessPolicyMode.anyOf => _evaluateAnyOf(context),
      _AccessPolicyMode.not => _evaluateNot(context),
    };
  }

  AccessDecision _evaluateLeaf(AccessContext context) {
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

  AccessDecision _evaluateAllOf(AccessContext context) {
    final reasons = <String>[];
    for (final policy in _policies) {
      final decision = policy.evaluate(context);
      if (decision.denied) {
        reasons.addAll(decision.reasons);
      }
    }

    if (reasons.isEmpty) {
      return AccessDecision.allow;
    }
    return AccessDecision.deny(reasons);
  }

  AccessDecision _evaluateAnyOf(AccessContext context) {
    if (_policies.isEmpty) {
      return AccessDecision.deny(const <String>[
        'Requires at least one policy to allow access.',
      ]);
    }

    final reasons = <String>[];
    for (final policy in _policies) {
      final decision = policy.evaluate(context);
      if (decision.allowed) {
        return AccessDecision.allow;
      }
      reasons.addAll(decision.reasons);
    }

    return AccessDecision.deny(reasons);
  }

  AccessDecision _evaluateNot(AccessContext context) {
    final decision = _policies.single.evaluate(context);
    if (decision.denied) {
      return AccessDecision.allow;
    }
    return AccessDecision.deny(<String>[_notReason]);
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
