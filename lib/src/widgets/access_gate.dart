import 'package:flutter/widgets.dart';

import '../access_context.dart';
import '../access_controller.dart';
import '../access_decision.dart';
import '../access_key.dart';
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
    this.policy = AccessPolicy.empty,
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

  /// Creates an access gate from inline typed key requirements.
  AccessGate.whenKeys({
    super.key,
    required this.child,
    this.fallback,
    this.fallbackBuilder,
    this.controller,
    this.accessContext,
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
  }) : policy = AccessPolicy.fromKeys(
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

  /// Creates an access gate that requires typed [feature].
  AccessGate.featureKey({
    super.key,
    required AccessFeature feature,
    required this.child,
    this.fallback,
    this.fallbackBuilder,
    this.controller,
    this.accessContext,
  }) : policy = AccessPolicy.featureKey(feature),
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

  /// Creates an access gate that requires typed [role].
  AccessGate.roleKey({
    super.key,
    required AccessRole role,
    required this.child,
    this.fallback,
    this.fallbackBuilder,
    this.controller,
    this.accessContext,
  }) : policy = AccessPolicy.roleKey(role),
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

  /// Creates an access gate that requires typed [permission].
  AccessGate.permissionKey({
    super.key,
    required AccessPermission permission,
    required this.child,
    this.fallback,
    this.fallbackBuilder,
    this.controller,
    this.accessContext,
  }) : policy = AccessPolicy.permissionKey(permission),
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
    final explicitContext = accessContext;
    if (explicitContext != null) {
      return _buildForDecision(
        context,
        policy.evaluate(explicitContext),
        child,
      );
    }

    final explicitController = controller;
    if (explicitController != null) {
      return ListenableBuilder(
        listenable: explicitController,
        child: child,
        builder: (context, allowedChild) {
          return _buildForDecision(
            context,
            explicitController.evaluate(policy),
            allowedChild!,
          );
        },
      );
    }

    final scopedController = AccessScope.maybeOf(context);
    final decision =
        scopedController?.evaluate(policy) ??
        policy.evaluate(const AccessContext.empty());
    return _buildForDecision(context, decision, child);
  }

  Widget _buildForDecision(
    BuildContext context,
    AccessDecision decision,
    Widget allowedChild,
  ) {
    if (decision.allowed) {
      return allowedChild;
    }

    final builder = fallbackBuilder;
    if (builder != null) {
      return builder(context, decision);
    }
    return fallback ?? accessHidden;
  }
}
