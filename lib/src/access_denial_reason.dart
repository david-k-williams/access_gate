import 'package:flutter/foundation.dart';

/// The category of a denied access decision.
enum AccessDenialReasonType {
  /// A required feature flag was not enabled.
  missingFeature,

  /// None of a set of feature flags was enabled.
  missingAnyFeature,

  /// A feature flag value did not match the required value.
  featureValueMismatch,

  /// A required role was not present.
  missingRole,

  /// None of a set of roles was present.
  missingAnyRole,

  /// A required permission was not present.
  missingPermission,

  /// None of a set of permissions was present.
  missingAnyPermission,

  /// An attribute value did not match the required value.
  attributeMismatch,

  /// A custom predicate rejected access.
  predicateRejected,

  /// An empty any-of policy set rejected access.
  emptyPolicySet,

  /// A not policy matched the denied child policy.
  notPolicyMatched,

  /// A custom string reason without a more specific category.
  custom,
}

/// Structured explanation for why access was denied.
@immutable
class AccessDenialReason {
  /// Creates a denial reason.
  AccessDenialReason({
    required this.type,
    required this.message,
    this.key,
    this.policyLabel,
    this.expected,
    this.actual,
    Set<String> candidates = const <String>{},
  }) : candidates = Set<String>.unmodifiable(candidates);

  /// Creates a custom denial reason from a message.
  factory AccessDenialReason.custom(String message) {
    return AccessDenialReason(
      type: AccessDenialReasonType.custom,
      message: message,
    );
  }

  /// Machine-readable category for this denial reason.
  final AccessDenialReasonType type;

  /// Human-readable message suitable for simple fallback UI.
  final String message;

  /// Primary key involved in the failure, such as a role or permission.
  final String? key;

  /// Optional label of the policy that produced this reason.
  final String? policyLabel;

  /// Expected value for mismatch failures.
  final Object? expected;

  /// Actual value for mismatch failures.
  final Object? actual;

  /// Candidate keys involved in any-of failures.
  final Set<String> candidates;

  @override
  bool operator ==(Object other) {
    return other is AccessDenialReason &&
        other.type == type &&
        other.message == message &&
        other.key == key &&
        other.policyLabel == policyLabel &&
        other.expected == expected &&
        other.actual == actual &&
        setEquals(other.candidates, candidates);
  }

  @override
  int get hashCode {
    return Object.hash(
      type,
      message,
      key,
      policyLabel,
      expected,
      actual,
      Object.hashAllUnordered(candidates),
    );
  }

  @override
  String toString() {
    final values = <String>[
      'type: $type',
      if (policyLabel != null) 'policyLabel: $policyLabel',
      if (key != null) 'key: $key',
      if (expected != null) 'expected: $expected',
      if (actual != null) 'actual: $actual',
      if (candidates.isNotEmpty) 'candidates: $candidates',
      'message: $message',
    ];
    return 'AccessDenialReason(${values.join(', ')})';
  }
}
