import 'package:flutter/foundation.dart';

import 'access_context.dart';
import 'access_decision.dart';
import 'access_policy.dart';

/// Mutable access state for an [AccessScope].
class AccessController extends ChangeNotifier {
  /// Creates a controller with an optional initial [context].
  AccessController([AccessContext? context])
      : _context = context ?? const AccessContext.empty();

  AccessContext _context;

  /// Current access facts.
  AccessContext get context => _context;

  set context(AccessContext value) {
    if (value == _context) {
      return;
    }
    _context = value;
    notifyListeners();
  }

  /// Replaces the current access facts.
  void update(AccessContext value) {
    context = value;
  }

  /// Evaluates [policy] against the current [context].
  AccessDecision evaluate(AccessPolicy policy) => policy.evaluate(context);

  /// Returns whether [policy] is allowed for the current [context].
  bool can(AccessPolicy policy) => evaluate(policy).allowed;
}
