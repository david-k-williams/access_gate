import 'package:flutter/widgets.dart';

/// A widget that renders nothing and creates no render object.
///
/// This mirrors the useful behavior of packages like `nil`: it is valid in the
/// widget tree, but only creates an [Element]. Prefer omitting items entirely
/// from multi-child lists when possible.
class AccessHidden extends Widget {
  /// Creates a hidden access placeholder.
  const AccessHidden({super.key});

  @override
  Element createElement() => _AccessHiddenElement(this);
}

/// Reusable hidden widget returned by denied [AccessGate] widgets.
const AccessHidden accessHidden = AccessHidden();

class _AccessHiddenElement extends Element {
  _AccessHiddenElement(super.widget);

  @override
  bool get debugDoingBuild => false;

  @override
  void performRebuild() {
    super.performRebuild();
  }
}
