import 'package:flutter/widgets.dart';

import '../access_context.dart';
import '../access_controller.dart';
import '../access_decision.dart';
import '../access_policy.dart';
import 'access_hidden.dart';
import 'access_scope.dart';

/// Builds a fallback widget for a denied access decision.
typedef AccessFallbackBuilder =
    Widget Function(BuildContext context, AccessDecision decision);

/// Protects a widget behind feature flags, RBAC, permissions, and ABAC checks.
///
/// When access is denied, [AccessGate] renders [fallback], [fallbackBuilder],
/// or [accessHidden] by default.
class AccessGate extends StatelessWidget {
  /// Creates an access gate from a policy.
  const AccessGate({
    super.key,
    required this.child,
    this.policy = const AccessPolicy(),
    this.fallback,
    this.fallbackBuilder,
    this.controller,
    this.accessContext,
  }) : assert(
         fallback == null || fallbackBuilder == null,
         'Provide either fallback or fallbackBuilder, not both.',
       ),
       assert(
         controller == null || accessContext == null,
         'Provide either controller or accessContext, not both.',
       );

  /// Creates an access gate from inline requirements.
  AccessGate.when({
    super.key,
    required this.child,
    this.fallback,
    this.fallbackBuilder,
    this.controller,
    this.accessContext,
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
  }) : policy = AccessPolicy(
         allFeatures: allFeatures,
         anyFeatures: anyFeatures,
         featureValues: featureValues,
         allRoles: allRoles,
         anyRoles: anyRoles,
         allPermissions: allPermissions,
         anyPermissions: anyPermissions,
         attributes: attributes,
         predicate: predicate,
         predicateReason: predicateReason,
       ),
       assert(
         fallback == null || fallbackBuilder == null,
         'Provide either fallback or fallbackBuilder, not both.',
       ),
       assert(
         controller == null || accessContext == null,
         'Provide either controller or accessContext, not both.',
       );

  /// Creates an access gate that requires [feature].
  AccessGate.feature({
    super.key,
    required String feature,
    required this.child,
    this.fallback,
    this.fallbackBuilder,
    this.controller,
    this.accessContext,
  }) : policy = AccessPolicy.feature(feature),
       assert(
         fallback == null || fallbackBuilder == null,
         'Provide either fallback or fallbackBuilder, not both.',
       ),
       assert(
         controller == null || accessContext == null,
         'Provide either controller or accessContext, not both.',
       );

  /// Creates an access gate that requires [role].
  AccessGate.role({
    super.key,
    required String role,
    required this.child,
    this.fallback,
    this.fallbackBuilder,
    this.controller,
    this.accessContext,
  }) : policy = AccessPolicy.role(role),
       assert(
         fallback == null || fallbackBuilder == null,
         'Provide either fallback or fallbackBuilder, not both.',
       ),
       assert(
         controller == null || accessContext == null,
         'Provide either controller or accessContext, not both.',
       );

  /// Creates an access gate that requires [permission].
  AccessGate.permission({
    super.key,
    required String permission,
    required this.child,
    this.fallback,
    this.fallbackBuilder,
    this.controller,
    this.accessContext,
  }) : policy = AccessPolicy.permission(permission),
       assert(
         fallback == null || fallbackBuilder == null,
         'Provide either fallback or fallbackBuilder, not both.',
       ),
       assert(
         controller == null || accessContext == null,
         'Provide either controller or accessContext, not both.',
       );

  /// Widget shown when access is allowed.
  final Widget child;

  /// Policy evaluated to decide whether [child] is visible.
  final AccessPolicy policy;

  /// Optional static widget shown when access is denied.
  final Widget? fallback;

  /// Optional builder shown when access is denied.
  final AccessFallbackBuilder? fallbackBuilder;

  /// Optional controller. When omitted, the nearest [AccessScope] is used.
  final AccessController? controller;

  /// Optional one-off context, useful for tests or isolated gates.
  final AccessContext? accessContext;

  @override
  Widget build(BuildContext context) {
    final decision = _decisionFor(context);
    if (decision.allowed) {
      return child;
    }

    final builder = fallbackBuilder;
    if (builder != null) {
      return builder(context, decision);
    }
    return fallback ?? accessHidden;
  }

  AccessDecision _decisionFor(BuildContext context) {
    final explicitContext = accessContext;
    if (explicitContext != null) {
      return policy.evaluate(explicitContext);
    }

    final explicitController = controller;
    if (explicitController != null) {
      return explicitController.evaluate(policy);
    }

    final scopedController = AccessScope.maybeOf(context);
    if (scopedController != null) {
      return scopedController.evaluate(policy);
    }

    return policy.evaluate(const AccessContext.empty());
  }
}
