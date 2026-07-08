import 'package:flutter/foundation.dart';

/// Result of evaluating an [AccessPolicy].
@immutable
class AccessDecision {
  const AccessDecision._({required this.allowed, required this.reasons});

  /// Creates an access decision.
  factory AccessDecision({
    required bool allowed,
    Iterable<String> reasons = const <String>[],
  }) {
    return AccessDecision._(
      allowed: allowed,
      reasons: List<String>.unmodifiable(reasons),
    );
  }

  /// A reusable allowed decision.
  static const AccessDecision allow = AccessDecision._(
    allowed: true,
    reasons: <String>[],
  );

  /// Creates a denied decision with immutable [reasons].
  factory AccessDecision.deny(Iterable<String> reasons) {
    return AccessDecision._(
      allowed: false,
      reasons: List<String>.unmodifiable(reasons),
    );
  }

  /// Whether access was granted.
  final bool allowed;

  /// Human-readable explanations for a denied decision.
  final List<String> reasons;

  /// Whether access was denied.
  bool get denied => !allowed;
}
