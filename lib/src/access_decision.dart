import 'package:flutter/foundation.dart';

/// Result of evaluating an [AccessPolicy].
@immutable
class AccessDecision {
  /// Creates an access decision.
  const AccessDecision({
    required this.allowed,
    this.reasons = const <String>[],
  });

  /// A reusable allowed decision.
  static const AccessDecision allow = AccessDecision(allowed: true);

  /// Creates a denied decision with immutable [reasons].
  factory AccessDecision.deny(Iterable<String> reasons) {
    return AccessDecision(
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
