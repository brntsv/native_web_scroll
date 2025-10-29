import 'package:flutter/widgets.dart';

/// Signature for a builder that receives a [ScrollController] synchronized
/// with the platform's native scrolling on the current platform.
///
/// Used by `NativeScrollBuilder` to build the scrollable subtree.
typedef NativeScrollWidgetBuilder =
    Widget Function(BuildContext context, ScrollController controller);
