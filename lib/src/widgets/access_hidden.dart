import 'package:flutter/widgets.dart';

/// A zero-size widget used as the default denied fallback.
///
/// This creates a render object so it is safe inside multi-child render widgets
/// such as [Column], [Row], and [Stack].
class AccessHidden extends SizedBox {
  /// Creates a hidden access placeholder.
  const AccessHidden({super.key}) : super(width: 0, height: 0);
}

/// Reusable hidden widget returned by denied [AccessGate] widgets.
const AccessHidden accessHidden = AccessHidden();
