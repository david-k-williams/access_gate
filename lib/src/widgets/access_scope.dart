import 'package:flutter/widgets.dart';

import '../access_controller.dart';

/// Exposes an [AccessController] to descendant gates.
class AccessScope extends InheritedNotifier<AccessController> {
  /// Creates an access scope.
  const AccessScope({
    super.key,
    required AccessController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Returns the nearest [AccessController], or `null` when no scope exists.
  static AccessController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AccessScope>()?.notifier;
  }

  /// Returns the nearest [AccessController].
  ///
  /// Throws a [FlutterError] when no [AccessScope] is present.
  static AccessController of(BuildContext context) {
    final controller = maybeOf(context);
    if (controller == null) {
      throw FlutterError(
        'AccessScope.of() called with a context that does not contain an '
        'AccessScope. Add AccessScope above this widget or pass an '
        'AccessController directly.',
      );
    }
    return controller;
  }
}
