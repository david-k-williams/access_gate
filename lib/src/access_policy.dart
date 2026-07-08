import 'package:flutter/foundation.dart';

import 'access_context.dart';
import 'access_decision.dart';
import 'access_denial_reason.dart';
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

  /// Creates a serializable policy from JSON-compatible data.
  ///
  /// Predicates cannot be restored from JSON. Use [predicate] directly for
  /// runtime-only checks.
  factory AccessPolicy.fromJson(Map<String, Object?> json) {
    final type = json['type'] as String? ?? 'leaf';
    return switch (type) {
      'leaf' => AccessPolicy(
        allFeatures: _stringSetFromJson(json['allFeatures']),
        anyFeatures: _stringSetFromJson(json['anyFeatures']),
        featureValues: _objectMapFromJson(json['featureValues']),
        allRoles: _stringSetFromJson(json['allRoles']),
        anyRoles: _stringSetFromJson(json['anyRoles']),
        allPermissions: _stringSetFromJson(json['allPermissions']),
        anyPermissions: _stringSetFromJson(json['anyPermissions']),
        attributes: _objectMapFromJson(json['attributes']),
        predicateReason:
            json['predicateReason'] as String? ??
            'Custom access rule rejected access.',
      ),
      'allOf' => AccessPolicy.allOf(_policiesFromJson(json['policies'])),
      'anyOf' => AccessPolicy.anyOf(_policiesFromJson(json['policies'])),
      'not' => AccessPolicy.not(
        AccessPolicy.fromJson(_mapFromJson(json['policy'], 'policy')),
        reason: json['reason'] as String? ?? _defaultNotReason,
      ),
      _ => throw ArgumentError.value(type, 'type', 'Unknown policy type.'),
    };
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

  /// Converts this policy into JSON-compatible data.
  ///
  /// Policies with a custom predicate cannot be serialized because functions are
  /// runtime-only values.
  Map<String, Object?> toJson() {
    return switch (_mode) {
      _AccessPolicyMode.leaf => _leafToJson(),
      _AccessPolicyMode.allOf => <String, Object?>{
        'type': 'allOf',
        'policies': _policies.map((policy) => policy.toJson()).toList(),
      },
      _AccessPolicyMode.anyOf => <String, Object?>{
        'type': 'anyOf',
        'policies': _policies.map((policy) => policy.toJson()).toList(),
      },
      _AccessPolicyMode.not => <String, Object?>{
        'type': 'not',
        'policy': _policies.single.toJson(),
        'reason': _notReason,
      },
    };
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

    final reasons = <AccessDenialReason>[];
    _requireAll(
      reasons: reasons,
      values: allFeatures,
      hasValue: context.hasFeature,
      missingReason: (feature) => AccessDenialReason(
        type: AccessDenialReasonType.missingFeature,
        key: feature,
        message: 'Missing feature flag: $feature.',
      ),
    );
    _requireAny(
      reasons: reasons,
      values: anyFeatures,
      hasValue: context.hasFeature,
      missingReason: (features) => AccessDenialReason(
        type: AccessDenialReasonType.missingAnyFeature,
        candidates: features,
        message: 'Requires at least one feature flag: ${features.join(', ')}.',
      ),
    );

    for (final requirement in featureValues.entries) {
      final actual = context.featureValue(requirement.key);
      if (actual != requirement.value) {
        reasons.add(
          AccessDenialReason(
            type: AccessDenialReasonType.featureValueMismatch,
            key: requirement.key,
            expected: requirement.value,
            actual: actual,
            message:
                'Feature ${requirement.key} must equal ${requirement.value}.',
          ),
        );
      }
    }

    _requireAll(
      reasons: reasons,
      values: allRoles,
      hasValue: context.hasRole,
      missingReason: (role) => AccessDenialReason(
        type: AccessDenialReasonType.missingRole,
        key: role,
        message: 'Missing role: $role.',
      ),
    );
    _requireAny(
      reasons: reasons,
      values: anyRoles,
      hasValue: context.hasRole,
      missingReason: (roles) => AccessDenialReason(
        type: AccessDenialReasonType.missingAnyRole,
        candidates: roles,
        message: 'Requires at least one role: ${roles.join(', ')}.',
      ),
    );

    _requireAll(
      reasons: reasons,
      values: allPermissions,
      hasValue: context.hasPermission,
      missingReason: (permission) => AccessDenialReason(
        type: AccessDenialReasonType.missingPermission,
        key: permission,
        message: 'Missing permission: $permission.',
      ),
    );
    _requireAny(
      reasons: reasons,
      values: anyPermissions,
      hasValue: context.hasPermission,
      missingReason: (permissions) => AccessDenialReason(
        type: AccessDenialReasonType.missingAnyPermission,
        candidates: permissions,
        message: 'Requires at least one permission: ${permissions.join(', ')}.',
      ),
    );

    for (final requirement in attributes.entries) {
      final actual = context.attribute(requirement.key);
      if (actual != requirement.value) {
        reasons.add(
          AccessDenialReason(
            type: AccessDenialReasonType.attributeMismatch,
            key: requirement.key,
            expected: requirement.value,
            actual: actual,
            message:
                'Attribute ${requirement.key} must equal ${requirement.value}.',
          ),
        );
      }
    }

    final predicate = this.predicate;
    if (predicate != null && !predicate(context)) {
      reasons.add(
        AccessDenialReason(
          type: AccessDenialReasonType.predicateRejected,
          message: predicateReason,
        ),
      );
    }

    if (reasons.isEmpty) {
      return AccessDecision.allow;
    }
    return AccessDecision.denyWithReasons(reasons);
  }

  AccessDecision _evaluateAllOf(AccessContext context) {
    final reasons = <AccessDenialReason>[];
    for (final policy in _policies) {
      final decision = policy.evaluate(context);
      if (decision.denied) {
        reasons.addAll(decision.denialReasons);
      }
    }

    if (reasons.isEmpty) {
      return AccessDecision.allow;
    }
    return AccessDecision.denyWithReasons(reasons);
  }

  AccessDecision _evaluateAnyOf(AccessContext context) {
    if (_policies.isEmpty) {
      return AccessDecision.denyWithReasons(<AccessDenialReason>[
        AccessDenialReason(
          type: AccessDenialReasonType.emptyPolicySet,
          message: 'Requires at least one policy to allow access.',
        ),
      ]);
    }

    final reasons = <AccessDenialReason>[];
    for (final policy in _policies) {
      final decision = policy.evaluate(context);
      if (decision.allowed) {
        return AccessDecision.allow;
      }
      reasons.addAll(decision.denialReasons);
    }

    return AccessDecision.denyWithReasons(reasons);
  }

  AccessDecision _evaluateNot(AccessContext context) {
    final decision = _policies.single.evaluate(context);
    if (decision.denied) {
      return AccessDecision.allow;
    }
    return AccessDecision.denyWithReasons(<AccessDenialReason>[
      AccessDenialReason(
        type: AccessDenialReasonType.notPolicyMatched,
        message: _notReason,
      ),
    ]);
  }

  static void _requireAll({
    required List<AccessDenialReason> reasons,
    required Set<String> values,
    required bool Function(String value) hasValue,
    required AccessDenialReason Function(String value) missingReason,
  }) {
    for (final value in values) {
      if (!hasValue(value)) {
        reasons.add(missingReason(value));
      }
    }
  }

  static void _requireAny({
    required List<AccessDenialReason> reasons,
    required Set<String> values,
    required bool Function(String value) hasValue,
    required AccessDenialReason Function(Set<String> values) missingReason,
  }) {
    if (values.isNotEmpty && !values.any(hasValue)) {
      reasons.add(missingReason(values));
    }
  }

  Map<String, Object?> _leafToJson() {
    if (predicate != null) {
      throw UnsupportedError(
        'AccessPolicy predicates cannot be serialized to JSON.',
      );
    }

    return <String, Object?>{
      'type': 'leaf',
      'allFeatures': _sortedStrings(allFeatures),
      'anyFeatures': _sortedStrings(anyFeatures),
      'featureValues': _sortedMap(featureValues),
      'allRoles': _sortedStrings(allRoles),
      'anyRoles': _sortedStrings(anyRoles),
      'allPermissions': _sortedStrings(allPermissions),
      'anyPermissions': _sortedStrings(anyPermissions),
      'attributes': _sortedMap(attributes),
      'predicateReason': predicateReason,
    };
  }

  static List<AccessPolicy> _policiesFromJson(Object? value) {
    if (value == null) {
      return const <AccessPolicy>[];
    }
    return (value as Iterable)
        .map((item) => AccessPolicy.fromJson(_mapFromJson(item, 'policies')))
        .toList();
  }

  static Set<String> _stringSetFromJson(Object? value) {
    if (value == null) {
      return const <String>{};
    }
    return Set<String>.unmodifiable((value as Iterable).cast<String>());
  }

  static Map<String, Object?> _objectMapFromJson(Object? value) {
    if (value == null) {
      return const <String, Object?>{};
    }
    return Map<String, Object?>.unmodifiable(
      (value as Map).cast<String, Object?>(),
    );
  }

  static Map<String, Object?> _mapFromJson(Object? value, String key) {
    if (value is Map<String, Object?>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, Object?>();
    }
    throw ArgumentError.value(value, key, 'Expected a JSON object.');
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
