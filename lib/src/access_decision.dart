import 'package:flutter/foundation.dart';

import 'access_denial_reason.dart';

/// Result of evaluating an [AccessPolicy].
@immutable
class AccessDecision {
  const AccessDecision._({
    required this.allowed,
    required this.reasons,
    required this.denialReasons,
  });

  /// Creates an access decision.
  factory AccessDecision({
    required bool allowed,
    Iterable<String> reasons = const <String>[],
    Iterable<AccessDenialReason> denialReasons = const <AccessDenialReason>[],
  }) {
    final typedReasons = <AccessDenialReason>[
      ...denialReasons,
      ...reasons.map(AccessDenialReason.custom),
    ];
    if (allowed && typedReasons.isNotEmpty) {
      throw ArgumentError(
        'Allowed access decisions cannot contain denial reasons.',
      );
    }
    return AccessDecision._(
      allowed: allowed,
      reasons: List<String>.unmodifiable(
        typedReasons.map((reason) => reason.message),
      ),
      denialReasons: List<AccessDenialReason>.unmodifiable(typedReasons),
    );
  }

  /// A reusable allowed decision.
  static const AccessDecision allow = AccessDecision._(
    allowed: true,
    reasons: <String>[],
    denialReasons: <AccessDenialReason>[],
  );

  /// Creates a denied decision with immutable [reasons].
  factory AccessDecision.deny(Iterable<String> reasons) {
    return AccessDecision(allowed: false, reasons: reasons);
  }

  /// Creates a denied decision with structured [denialReasons].
  factory AccessDecision.denyWithReasons(
    Iterable<AccessDenialReason> denialReasons,
  ) {
    return AccessDecision(allowed: false, denialReasons: denialReasons);
  }

  /// Whether access was granted.
  final bool allowed;

  /// Human-readable explanations for a denied decision.
  final List<String> reasons;

  /// Structured explanations for a denied decision.
  final List<AccessDenialReason> denialReasons;

  /// Whether access was denied.
  bool get denied => !allowed;

  @override
  bool operator ==(Object other) {
    return other is AccessDecision &&
        other.allowed == allowed &&
        listEquals(other.reasons, reasons) &&
        listEquals(other.denialReasons, denialReasons);
  }

  @override
  int get hashCode {
    return Object.hash(
      allowed,
      Object.hashAll(reasons),
      Object.hashAll(denialReasons),
    );
  }

  @override
  String toString() {
    return 'AccessDecision(allowed: $allowed, reasons: $reasons)';
  }
}
