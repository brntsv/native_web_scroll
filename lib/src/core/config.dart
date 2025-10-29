import 'package:flutter/widgets.dart';

/// {@template config.class}
/// Immutable configuration for `NativeScrollBuilder` behavior.
///
/// This config influences both Flutter-side rendering (e.g. scrollbar behavior)
/// and the web DOM adapter (e.g. axis and wheel propagation).
/// {@endtemplate}
class NativeScrollConfig {
  /// {@macro config.class}
  const NativeScrollConfig({
    this.axis = Axis.vertical,
    this.hideFlutterScrollbars = true,
    this.stopWheelPropagation = true,
  });

  /// Scroll axis for both Flutter and DOM synchronization.
  final Axis axis;

  /// Whether to hide Flutter's Scrollbars via [ScrollConfiguration].
  ///
  /// This does not affect the native DOM scrollbar visibility.
  final bool hideFlutterScrollbars;

  /// Whether to stop native wheel events from propagating to parent views.
  ///
  /// Useful when embedding in other platform views to avoid nested scroll
  /// conflicts.
  final bool stopWheelPropagation;
}
