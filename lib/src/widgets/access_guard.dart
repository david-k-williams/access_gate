import 'package:flutter/widgets.dart';

import '../access_context.dart';
import '../access_controller.dart';
import '../access_decision.dart';
import '../access_policy.dart';
import 'access_builder.dart';
import 'access_hidden.dart';

/// Builds a page or route branch with the evaluated [AccessDecision].
typedef AccessGuardBuilder = Widget Function(
    BuildContext context, AccessDecision decision);

/// Page-level access guard for route bodies, tabs, or full-screen sections.
class AccessGuard extends StatelessWidget {
  /// Creates an access guard.
  const AccessGuard({
    super.key,
    required this.policy,
    required this.builder,
    this.denied,
    this.deniedBuilder,
    this.controller,
    this.accessContext,
  })  : assert(
          denied == null || deniedBuilder == null,
          'Provide either denied or deniedBuilder, not both.',
        ),
        assert(
          controller == null || accessContext == null,
          'Provide either controller or accessContext, not both.',
        );

  /// Policy evaluated before calling [builder] or [deniedBuilder].
  final AccessPolicy policy;

  /// Builder used when access is allowed.
  final AccessGuardBuilder builder;

  /// Optional static widget shown when access is denied.
  final Widget? denied;

  /// Optional builder used when access is denied.
  final AccessGuardBuilder? deniedBuilder;

  /// Optional controller. When omitted, the nearest [AccessScope] is used.
  final AccessController? controller;

  /// Optional one-off context, useful for tests or isolated guards.
  final AccessContext? accessContext;

  @override
  Widget build(BuildContext context) {
    return AccessBuilder(
      policy: policy,
      controller: controller,
      accessContext: accessContext,
      builder: (context, decision) {
        if (decision.allowed) {
          return builder(context, decision);
        }

        final deniedBuilder = this.deniedBuilder;
        if (deniedBuilder != null) {
          return deniedBuilder(context, decision);
        }
        return denied ?? accessHidden;
      },
    );
  }
}
