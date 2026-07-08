/// Widget-level access control for Flutter.
///
/// Use [AccessScope] to expose the current user's access context, then wrap
/// protected UI in [AccessGate]. Denied gates render [accessHidden] by default,
/// which creates an element only and does not add a render object.
library;

export 'src/access_context.dart';
export 'src/access_controller.dart';
export 'src/access_decision.dart';
export 'src/access_denial_reason.dart';
export 'src/access_key.dart';
export 'src/access_policy.dart';
export 'src/widgets/access_builder.dart';
export 'src/widgets/access_gate.dart';
export 'src/widgets/access_guard.dart';
export 'src/widgets/access_hidden.dart';
export 'src/widgets/access_scope.dart';
