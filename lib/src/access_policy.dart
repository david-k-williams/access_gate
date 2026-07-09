import 'package:flutter/foundation.dart';

import 'access_context.dart';
import 'access_decision.dart';
import 'access_denial_reason.dart';
import 'access_key.dart';
import 'access_value.dart';

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
    required this.label,
    required _AccessPolicyMode mode,
    required List<AccessPolicy> policies,
    required String notReason,
  })  : _mode = mode,
        _policies = policies,
        _notReason = notReason;

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
    String? label,
  }) {
    return AccessPolicy._(
      allFeatures: Set<String>.unmodifiable(allFeatures),
      anyFeatures: Set<String>.unmodifiable(anyFeatures),
      featureValues: freezeAccessValueMap(featureValues),
      allRoles: Set<String>.unmodifiable(allRoles),
      anyRoles: Set<String>.unmodifiable(anyRoles),
      allPermissions: Set<String>.unmodifiable(allPermissions),
      anyPermissions: Set<String>.unmodifiable(anyPermissions),
      attributes: freezeAccessValueMap(attributes),
      predicate: predicate,
      predicateReason: predicateReason,
      label: label,
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
    label: null,
    mode: _AccessPolicyMode.leaf,
    policies: <AccessPolicy>[],
    notReason: _defaultNotReason,
  );

  /// Creates a policy that requires every child policy to allow access.
  factory AccessPolicy.allOf(Iterable<AccessPolicy> policies, {String? label}) {
    return AccessPolicy._composed(
      mode: _AccessPolicyMode.allOf,
      policies: policies,
      label: label,
    );
  }

  /// Creates a policy that requires at least one child policy to allow access.
  factory AccessPolicy.anyOf(Iterable<AccessPolicy> policies, {String? label}) {
    return AccessPolicy._composed(
      mode: _AccessPolicyMode.anyOf,
      policies: policies,
      label: label,
    );
  }

  /// Creates a policy that allows access only when [policy] denies access.
  factory AccessPolicy.not(
    AccessPolicy policy, {
    String reason = _defaultNotReason,
    String? label,
  }) {
    return AccessPolicy._composed(
      mode: _AccessPolicyMode.not,
      policies: <AccessPolicy>[policy],
      notReason: reason,
      label: label,
    );
  }

  factory AccessPolicy._composed({
    required _AccessPolicyMode mode,
    required Iterable<AccessPolicy> policies,
    String notReason = _defaultNotReason,
    String? label,
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
      label: label,
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
    final type = jsonOptionalString(json, 'type') ?? 'leaf';
    return switch (type) {
      'leaf' => AccessPolicy(
          allFeatures: jsonStringSet(json['allFeatures'], 'allFeatures'),
          anyFeatures: jsonStringSet(json['anyFeatures'], 'anyFeatures'),
          featureValues: jsonAccessValueMap(
            json['featureValues'],
            'featureValues',
          ),
          allRoles: jsonStringSet(json['allRoles'], 'allRoles'),
          anyRoles: jsonStringSet(json['anyRoles'], 'anyRoles'),
          allPermissions:
              jsonStringSet(json['allPermissions'], 'allPermissions'),
          anyPermissions:
              jsonStringSet(json['anyPermissions'], 'anyPermissions'),
          attributes: jsonAccessValueMap(json['attributes'], 'attributes'),
          predicateReason: jsonOptionalString(json, 'predicateReason') ??
              'Custom access rule rejected access.',
          label: jsonOptionalString(json, 'label'),
        ),
      'allOf' => AccessPolicy.allOf(
          _policiesFromJson(json['policies']),
          label: jsonOptionalString(json, 'label'),
        ),
      'anyOf' => AccessPolicy.anyOf(
          _policiesFromJson(json['policies']),
          label: jsonOptionalString(json, 'label'),
        ),
      'not' => AccessPolicy.not(
          AccessPolicy.fromJson(_mapFromJson(json['policy'], 'policy')),
          reason: jsonOptionalString(json, 'reason') ?? _defaultNotReason,
          label: jsonOptionalString(json, 'label'),
        ),
      _ => throw FormatException('Unknown policy type: $type.'),
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
    String? label,
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
      label: label,
    );
  }

  /// Creates a policy that requires a single enabled feature.
  factory AccessPolicy.feature(String feature, {String? label}) {
    return AccessPolicy(allFeatures: <String>{feature}, label: label);
  }

  /// Creates a policy that requires a single enabled typed feature key.
  factory AccessPolicy.featureKey(AccessFeature feature, {String? label}) {
    return AccessPolicy.feature(feature.accessKey, label: label);
  }

  /// Creates a policy that requires at least one enabled feature.
  factory AccessPolicy.anyFeature(Iterable<String> features, {String? label}) {
    return AccessPolicy(anyFeatures: Set<String>.of(features), label: label);
  }

  /// Creates a policy that requires at least one enabled typed feature key.
  factory AccessPolicy.anyFeatureKey(
    Iterable<AccessFeature> features, {
    String? label,
  }) {
    return AccessPolicy.anyFeature(accessKeySet(features), label: label);
  }

  /// Creates a policy that requires a feature to exactly match [value].
  factory AccessPolicy.featureValue(
    String feature,
    Object? value, {
    String? label,
  }) {
    return AccessPolicy(
      featureValues: <String, Object?>{feature: value},
      label: label,
    );
  }

  /// Creates a policy that requires a typed feature to exactly match [value].
  factory AccessPolicy.featureValueKey(
    AccessFeature feature,
    Object? value, {
    String? label,
  }) {
    return AccessPolicy.featureValue(feature.accessKey, value, label: label);
  }

  /// Creates a policy that requires a single role.
  factory AccessPolicy.role(String role, {String? label}) {
    return AccessPolicy(allRoles: <String>{role}, label: label);
  }

  /// Creates a policy that requires a single typed role key.
  factory AccessPolicy.roleKey(AccessRole role, {String? label}) {
    return AccessPolicy.role(role.accessKey, label: label);
  }

  /// Creates a policy that requires at least one role.
  factory AccessPolicy.anyRole(Iterable<String> roles, {String? label}) {
    return AccessPolicy(anyRoles: Set<String>.of(roles), label: label);
  }

  /// Creates a policy that requires at least one typed role key.
  factory AccessPolicy.anyRoleKey(Iterable<AccessRole> roles, {String? label}) {
    return AccessPolicy.anyRole(accessKeySet(roles), label: label);
  }

  /// Creates a policy that requires a single permission.
  factory AccessPolicy.permission(String permission, {String? label}) {
    return AccessPolicy(allPermissions: <String>{permission}, label: label);
  }

  /// Creates a policy that requires a single typed permission key.
  factory AccessPolicy.permissionKey(
    AccessPermission permission, {
    String? label,
  }) {
    return AccessPolicy.permission(permission.accessKey, label: label);
  }

  /// Creates a policy that requires at least one permission.
  factory AccessPolicy.anyPermission(
    Iterable<String> permissions, {
    String? label,
  }) {
    return AccessPolicy(
      anyPermissions: Set<String>.of(permissions),
      label: label,
    );
  }

  /// Creates a policy that requires at least one typed permission key.
  factory AccessPolicy.anyPermissionKey(
    Iterable<AccessPermission> permissions, {
    String? label,
  }) {
    return AccessPolicy.anyPermission(accessKeySet(permissions), label: label);
  }

  /// Creates a policy that requires an attribute to exactly match [value].
  factory AccessPolicy.attribute(
    String attribute,
    Object? value, {
    String? label,
  }) {
    return AccessPolicy(
      attributes: <String, Object?>{attribute: value},
      label: label,
    );
  }

  /// Creates a policy that requires a typed attribute to exactly match [value].
  factory AccessPolicy.attributeKey(
    AccessAttribute attribute,
    Object? value, {
    String? label,
  }) {
    return AccessPolicy.attribute(attribute.accessKey, value, label: label);
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

  /// Optional human-readable label used in diagnostics and denial reasons.
  final String? label;

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
          'label': label,
          'policies': _policies.map((policy) => policy.toJson()).toList(),
        },
      _AccessPolicyMode.anyOf => <String, Object?>{
          'type': 'anyOf',
          'label': label,
          'policies': _policies.map((policy) => policy.toJson()).toList(),
        },
      _AccessPolicyMode.not => <String, Object?>{
          'type': 'not',
          'label': label,
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
        policyLabel: label,
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
        policyLabel: label,
        message: 'Requires at least one feature flag: ${features.join(', ')}.',
      ),
    );

    for (final requirement in featureValues.entries) {
      final actual = context.featureValue(requirement.key);
      if (!accessValueEquals(actual, requirement.value)) {
        reasons.add(
          AccessDenialReason(
            type: AccessDenialReasonType.featureValueMismatch,
            key: requirement.key,
            policyLabel: label,
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
        policyLabel: label,
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
        policyLabel: label,
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
        policyLabel: label,
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
        policyLabel: label,
        message: 'Requires at least one permission: ${permissions.join(', ')}.',
      ),
    );

    for (final requirement in attributes.entries) {
      final actual = context.attribute(requirement.key);
      if (!accessValueEquals(actual, requirement.value)) {
        reasons.add(
          AccessDenialReason(
            type: AccessDenialReasonType.attributeMismatch,
            key: requirement.key,
            policyLabel: label,
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
          policyLabel: label,
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
          policyLabel: label,
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
        policyLabel: label,
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
      'label': label,
    };
  }

  @override
  String toString() {
    return switch (_mode) {
      _AccessPolicyMode.leaf => _leafToString(),
      _AccessPolicyMode.allOf =>
        'AccessPolicy.allOf(label: $label, policies: ${_policies.length})',
      _AccessPolicyMode.anyOf =>
        'AccessPolicy.anyOf(label: $label, policies: ${_policies.length})',
      _AccessPolicyMode.not =>
        'AccessPolicy.not(label: $label, reason: $_notReason)',
    };
  }

  static List<AccessPolicy> _policiesFromJson(Object? value) {
    if (value == null) {
      return const <AccessPolicy>[];
    }
    if (value is! Iterable || value is String) {
      throw const FormatException('Expected "policies" to be a list.');
    }
    return value
        .map((item) => AccessPolicy.fromJson(_mapFromJson(item, 'policies')))
        .toList();
  }

  static Map<String, Object?> _mapFromJson(Object? value, String key) {
    return jsonObject(value, key);
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

  String _leafToString() {
    final requirements = <String>[
      if (allFeatures.isNotEmpty) 'allFeatures: $allFeatures',
      if (anyFeatures.isNotEmpty) 'anyFeatures: $anyFeatures',
      if (featureValues.isNotEmpty) 'featureValues: $featureValues',
      if (allRoles.isNotEmpty) 'allRoles: $allRoles',
      if (anyRoles.isNotEmpty) 'anyRoles: $anyRoles',
      if (allPermissions.isNotEmpty) 'allPermissions: $allPermissions',
      if (anyPermissions.isNotEmpty) 'anyPermissions: $anyPermissions',
      if (attributes.isNotEmpty) 'attributes: $attributes',
      if (predicate != null) 'predicate: true',
      if (label != null) 'label: $label',
    ];
    return 'AccessPolicy(${requirements.join(', ')})';
  }
}
