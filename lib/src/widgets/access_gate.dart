import 'package:flutter/widgets.dart';

import '../access_context.dart';
import '../access_controller.dart';
import '../access_decision.dart';
import '../access_key.dart';
import '../access_policy.dart';
import 'access_hidden.dart';
import 'access_scope.dart';

/// Builds a fallback widget for a denied access decision.
typedef AccessFallbackBuilder = Widget Function(
    BuildContext context, AccessDecision decision);

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
  })  : assert(
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
    String? label,
  })  : policy = AccessPolicy(
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
          label: label,
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
    String? label,
  })  : policy = AccessPolicy.fromKeys(
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
          label: label,
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
    String? label,
  })  : policy = AccessPolicy.feature(feature, label: label),
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
    String? label,
  })  : policy = AccessPolicy.featureKey(feature, label: label),
        assert(
          fallback == null || fallbackBuilder == null,
          'Provide either fallback or fallbackBuilder, not both.',
        ),
        assert(
          controller == null || accessContext == null,
          'Provide either controller or accessContext, not both.',
        );

  /// Creates an access gate that requires at least one [features] item.
  AccessGate.anyFeature({
    super.key,
    required Iterable<String> features,
    required this.child,
    this.fallback,
    this.fallbackBuilder,
    this.controller,
    this.accessContext,
    String? label,
  })  : policy = AccessPolicy.anyFeature(features, label: label),
        assert(
          fallback == null || fallbackBuilder == null,
          'Provide either fallback or fallbackBuilder, not both.',
        ),
        assert(
          controller == null || accessContext == null,
          'Provide either controller or accessContext, not both.',
        );

  /// Creates an access gate that requires at least one typed [features] item.
  AccessGate.anyFeatureKey({
    super.key,
    required Iterable<AccessFeature> features,
    required this.child,
    this.fallback,
    this.fallbackBuilder,
    this.controller,
    this.accessContext,
    String? label,
  })  : policy = AccessPolicy.anyFeatureKey(features, label: label),
        assert(
          fallback == null || fallbackBuilder == null,
          'Provide either fallback or fallbackBuilder, not both.',
        ),
        assert(
          controller == null || accessContext == null,
          'Provide either controller or accessContext, not both.',
        );

  /// Creates an access gate that requires [feature] to exactly match [value].
  AccessGate.featureValue({
    super.key,
    required String feature,
    required Object? value,
    required this.child,
    this.fallback,
    this.fallbackBuilder,
    this.controller,
    this.accessContext,
    String? label,
  })  : policy = AccessPolicy.featureValue(feature, value, label: label),
        assert(
          fallback == null || fallbackBuilder == null,
          'Provide either fallback or fallbackBuilder, not both.',
        ),
        assert(
          controller == null || accessContext == null,
          'Provide either controller or accessContext, not both.',
        );

  /// Creates an access gate that requires typed [feature] to match [value].
  AccessGate.featureValueKey({
    super.key,
    required AccessFeature feature,
    required Object? value,
    required this.child,
    this.fallback,
    this.fallbackBuilder,
    this.controller,
    this.accessContext,
    String? label,
  })  : policy = AccessPolicy.featureValueKey(feature, value, label: label),
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
    String? label,
  })  : policy = AccessPolicy.role(role, label: label),
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
    String? label,
  })  : policy = AccessPolicy.roleKey(role, label: label),
        assert(
          fallback == null || fallbackBuilder == null,
          'Provide either fallback or fallbackBuilder, not both.',
        ),
        assert(
          controller == null || accessContext == null,
          'Provide either controller or accessContext, not both.',
        );

  /// Creates an access gate that requires at least one [roles] item.
  AccessGate.anyRole({
    super.key,
    required Iterable<String> roles,
    required this.child,
    this.fallback,
    this.fallbackBuilder,
    this.controller,
    this.accessContext,
    String? label,
  })  : policy = AccessPolicy.anyRole(roles, label: label),
        assert(
          fallback == null || fallbackBuilder == null,
          'Provide either fallback or fallbackBuilder, not both.',
        ),
        assert(
          controller == null || accessContext == null,
          'Provide either controller or accessContext, not both.',
        );

  /// Creates an access gate that requires at least one typed [roles] item.
  AccessGate.anyRoleKey({
    super.key,
    required Iterable<AccessRole> roles,
    required this.child,
    this.fallback,
    this.fallbackBuilder,
    this.controller,
    this.accessContext,
    String? label,
  })  : policy = AccessPolicy.anyRoleKey(roles, label: label),
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
    String? label,
  })  : policy = AccessPolicy.permission(permission, label: label),
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
    String? label,
  })  : policy = AccessPolicy.permissionKey(permission, label: label),
        assert(
          fallback == null || fallbackBuilder == null,
          'Provide either fallback or fallbackBuilder, not both.',
        ),
        assert(
          controller == null || accessContext == null,
          'Provide either controller or accessContext, not both.',
        );

  /// Creates an access gate that requires at least one [permissions] item.
  AccessGate.anyPermission({
    super.key,
    required Iterable<String> permissions,
    required this.child,
    this.fallback,
    this.fallbackBuilder,
    this.controller,
    this.accessContext,
    String? label,
  })  : policy = AccessPolicy.anyPermission(permissions, label: label),
        assert(
          fallback == null || fallbackBuilder == null,
          'Provide either fallback or fallbackBuilder, not both.',
        ),
        assert(
          controller == null || accessContext == null,
          'Provide either controller or accessContext, not both.',
        );

  /// Creates an access gate that requires at least one typed [permissions] item.
  AccessGate.anyPermissionKey({
    super.key,
    required Iterable<AccessPermission> permissions,
    required this.child,
    this.fallback,
    this.fallbackBuilder,
    this.controller,
    this.accessContext,
    String? label,
  })  : policy = AccessPolicy.anyPermissionKey(permissions, label: label),
        assert(
          fallback == null || fallbackBuilder == null,
          'Provide either fallback or fallbackBuilder, not both.',
        ),
        assert(
          controller == null || accessContext == null,
          'Provide either controller or accessContext, not both.',
        );

  /// Creates an access gate that requires [attribute] to exactly match [value].
  AccessGate.attribute({
    super.key,
    required String attribute,
    required Object? value,
    required this.child,
    this.fallback,
    this.fallbackBuilder,
    this.controller,
    this.accessContext,
    String? label,
  })  : policy = AccessPolicy.attribute(attribute, value, label: label),
        assert(
          fallback == null || fallbackBuilder == null,
          'Provide either fallback or fallbackBuilder, not both.',
        ),
        assert(
          controller == null || accessContext == null,
          'Provide either controller or accessContext, not both.',
        );

  /// Creates an access gate that requires typed [attribute] to match [value].
  AccessGate.attributeKey({
    super.key,
    required AccessAttribute attribute,
    required Object? value,
    required this.child,
    this.fallback,
    this.fallbackBuilder,
    this.controller,
    this.accessContext,
    String? label,
  })  : policy = AccessPolicy.attributeKey(attribute, value, label: label),
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
    final decision = scopedController?.evaluate(policy) ??
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
