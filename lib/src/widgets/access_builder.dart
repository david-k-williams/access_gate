import 'package:flutter/widgets.dart';

import '../access_context.dart';
import '../access_controller.dart';
import '../access_decision.dart';
import '../access_policy.dart';
import 'access_scope.dart';

/// Builds a widget with the evaluated [AccessDecision].
typedef AccessDecisionWidgetBuilder =
    Widget Function(BuildContext context, AccessDecision decision);

/// Lower-level builder for custom access-aware UI.
class AccessBuilder extends StatelessWidget {
  /// Creates an access-aware builder.
  const AccessBuilder({
    super.key,
    required this.policy,
    required this.builder,
    this.controller,
    this.accessContext,
  }) : assert(
         controller == null || accessContext == null,
         'Provide either controller or accessContext, not both.',
       );

  /// Policy evaluated before calling [builder].
  final AccessPolicy policy;

  /// Builder receiving the current access decision.
  final AccessDecisionWidgetBuilder builder;

  /// Optional controller. When omitted, the nearest [AccessScope] is used.
  final AccessController? controller;

  /// Optional one-off context, useful for tests or isolated builders.
  final AccessContext? accessContext;

  @override
  Widget build(BuildContext context) {
    return builder(context, _decisionFor(context));
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
